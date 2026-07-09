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

class OperacoesCaixaWebPage extends StatefulWidget {
  const OperacoesCaixaWebPage({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<OperacoesCaixaWebPage> createState() => _OperacoesCaixaWebPageState();
}

class _OperacoesCaixaWebPageState extends State<OperacoesCaixaWebPage> {
  final CaixaService _caixaService = CaixaModule.caixaService;
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _trocoInicialController = TextEditingController(text: '200,00');
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final TextEditingController _fechamentoDinheiroController = TextEditingController();
  final TextEditingController _fechamentoPixController = TextEditingController();
  final TextEditingController _fechamentoCartaoController = TextEditingController();
  final TextEditingController _fechamentoObservacaoController = TextEditingController();

  bool _isLoading = false;
  bool _vincularVenda = false;
  bool _mostrarPainelFechamento = false;
  bool _mostrarApenasHoje = true;

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
      final informacoesBasicas = await _caixaService.buscarInformacoesBasicasDoCaixa();

      if (mounted && informacoesBasicas.regionalizacao != null) {
        await context.read<LocaleSettingsProvider>().atualizarConfiguracaoDaEmpresaPorResponse(
              informacoesBasicas.regionalizacao!,
            );
      }

      final sessao = await _caixaService.buscarSessaoAtual();
      await UsuarioService().buscarDadosDoUsuario_atualizaProviders();

      final caixas = informacoesBasicas.caixaOuGuiche.isNotEmpty
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
        _caixaSelecionado = caixaPreferencial ??
            (_caixasDisponiveis.isNotEmpty ? _caixasDisponiveis.first : null);
        _tipoRecebimentoSelecionado = tipoPreferencial ??
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
      final movimentosComSomatorio =
          await _caixaService.buscarResumoDeMovimentosComSomatorio(idCaixaSessao);
      final resumo = await _caixaService.buscarResumo(idCaixaSessao);

      if (!mounted) return;
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
      const SnackBar(content: Text('Antes de lançar operações, faça a abertura do caixa.')),
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
    final content = Shortcuts(
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
        child: Focus(
          autofocus: true,
          child: _buildContent(context),
        ),
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(child: content),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading && _sessaoAtual == null && _resumo == null) {
      return _buildLoading(theme);
    }

    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.16),
      child: Column(
        children: <Widget>[
          _buildHeader(theme),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1120;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildKpis(theme),
                      const SizedBox(height: 12),
                      if (!_temCaixaAberto)
                        _buildPainelAbertura(theme)
                      else if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                children: <Widget>[
                                  _buildContextoOperacao(theme),
                                  const SizedBox(height: 12),
                                  _buildAtalhosOperacao(theme),
                                  const SizedBox(height: 12),
                                  _buildFormularioMovimento(theme),
                                  if (_mostrarPainelFechamento) ...<Widget>[
                                    const SizedBox(height: 12),
                                    _buildPainelFechamento(theme),
                                  ],
                                  const SizedBox(height: 12),
                                  _buildHistorico(theme),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(width: 390, child: _buildResumoLateral(theme)),
                          ],
                        )
                      else
                        Column(
                          children: <Widget>[
                            _buildContextoOperacao(theme),
                            const SizedBox(height: 12),
                            _buildResumoLateral(theme),
                            const SizedBox(height: 12),
                            _buildAtalhosOperacao(theme),
                            const SizedBox(height: 12),
                            _buildFormularioMovimento(theme),
                            if (_mostrarPainelFechamento) ...<Widget>[
                              const SizedBox(height: 12),
                              _buildPainelFechamento(theme),
                            ],
                            const SizedBox(height: 12),
                            _buildHistorico(theme),
                          ],
                        ),
                    ],
                  );
                },
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
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4)),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 20, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.14))),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.point_of_sale_rounded, color: theme.colorScheme.primary, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Operações de caixa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '$empresa • $movimentos movimento(s) • ${_temCaixaAberto ? 'Caixa aberto' : 'Aguardando abertura'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _carregarDadosIniciais(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Atualizar'),
              ),
              IconButton.filledTonal(
                onPressed: _sairDaTela,
                tooltip: 'Fechar',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpis(ThemeData theme) {
    final resumo = _resumo;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;
        final width = compact ? constraints.maxWidth : ((constraints.maxWidth - 36) / 4).clamp(210.0, 360.0);
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _summaryCard(theme, width: width, label: 'Saldo esperado', value: _formatCurrency(resumo?.saldoEsperado ?? 0), helper: _temCaixaAberto ? 'Caixa em operação' : 'Aguardando abertura', icon: Icons.account_balance_wallet_outlined, highlight: true),
            _summaryCard(theme, width: width, label: 'Entradas', value: _formatCurrency(resumo?.totalEntradas ?? 0), helper: 'Recebimentos e suprimentos', icon: Icons.south_west_rounded),
            _summaryCard(theme, width: width, label: 'Saídas', value: _formatCurrency(resumo?.totalSaidas ?? 0), helper: 'Sangrias e despesas', icon: Icons.north_east_rounded),
            _summaryCard(theme, width: width, label: 'Movimentos', value: '${resumo?.quantidadeMovimentos ?? _movimentos.length}', helper: _mostrarApenasHoje ? 'Filtro de hoje ativo' : 'Todos visíveis', icon: Icons.receipt_long_outlined),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    ThemeData theme, {
    required double width,
    required String label,
    required String value,
    required String helper,
    required IconData icon,
    bool highlight = false,
  }) {
    final colorScheme = theme.colorScheme;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlight ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: highlight ? colorScheme.primary : colorScheme.outline.withOpacity(0.12)),
          boxShadow: <BoxShadow>[
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: highlight ? Colors.white.withOpacity(0.15) : colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: highlight ? Colors.white : colorScheme.primary, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: highlight ? Colors.white.withOpacity(0.86) : colorScheme.onSurface.withOpacity(0.62), fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: highlight ? Colors.white : colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(helper, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: highlight ? Colors.white.withOpacity(0.78) : colorScheme.onSurface.withOpacity(0.56), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
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
          _sectionHeader(theme, title: 'Abertura de caixa', subtitle: 'Defina o caixa, o troco inicial e inicie a operação do dia.', icon: Icons.lock_open_rounded),
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
                  onChanged: (value) => setState(() => _caixaSelecionado = value),
                  itemLabel: (item) => item.nome,
                  hint: 'Selecione',
                ),
              ),
              _buildFieldBox(
                theme,
                width: 220,
                label: 'Troco inicial',
                child: _buildTextField(theme, controller: _trocoInicialController, hint: '0,00', prefix: 'R\$ '),
              ),
              _buildFieldBox(
                theme,
                width: 280,
                label: 'Colaborador responsável',
                child: _buildReadOnlyField(theme, UsuarioProvider().usuario?.nomeDeGuerra ?? '--'),
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
          _miniMetric(theme, title: 'Sessão', value: _sessaoAtual?.idSessaoCaixa ?? '--', icon: Icons.badge_outlined),
          _miniMetric(theme, title: 'Caixa', value: _sessaoAtual?.nomeCaixa ?? '--', icon: Icons.store_mall_directory_outlined),
          _miniMetric(theme, title: 'Abertura', value: _formatDateTime(_sessaoAtual?.dataHoraAbertura), icon: Icons.schedule_rounded),
          _miniMetric(theme, title: 'Troco inicial', value: _formatCurrency(_sessaoAtual?.valorAbertura ?? 0), icon: Icons.account_balance_wallet_outlined),
          _miniMetric(theme, title: 'Status', value: _labelSessao(_sessaoAtual?.status), icon: Icons.verified_outlined),
        ],
      ),
    );
  }

  Widget _miniMetric(ThemeData theme, {required String title, required String value, required IconData icon}) {
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
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtalhosOperacao(ThemeData theme) {
    final cards = <_AtalhoOperacaoData>[
      _AtalhoOperacaoData(tipo: OperacaoCaixaTipo.suprimento, titulo: 'Suprimento', descricao: 'Adicionar valores ao caixa para reforço operacional.', icone: Icons.add_card_rounded, cor: const Color(0xff0f766e)),
      _AtalhoOperacaoData(tipo: OperacaoCaixaTipo.sangria, titulo: 'Sangria', descricao: 'Retirar excesso de numerário para segurança.', icone: Icons.outbox_rounded, cor: const Color(0xffb45309)),
      _AtalhoOperacaoData(tipo: OperacaoCaixaTipo.retiradaDespesa, titulo: 'Despesa', descricao: 'Registrar saída operacional com justificativa.', icone: Icons.receipt_long_rounded, cor: const Color(0xffbe123c)),
      _AtalhoOperacaoData(tipo: OperacaoCaixaTipo.ajuste, titulo: 'Ajuste', descricao: 'Corrigir diferenças operacionais com rastreabilidade.', icone: Icons.tune_rounded, cor: const Color(0xff4338ca)),
      _AtalhoOperacaoData(tipo: OperacaoCaixaTipo.recebimentoAvulso, titulo: 'Recebimento avulso', descricao: 'Entrada operacional sem vínculo direto com venda.', icone: Icons.arrow_downward_rounded, cor: const Color(0xff047857)),
      _AtalhoOperacaoData(tipo: OperacaoCaixaTipo.pagamentoAvulso, titulo: 'Pagamento avulso', descricao: 'Saída operacional pontual com justificativa.', icone: Icons.arrow_upward_rounded, cor: const Color(0xff991b1b)),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _sectionHeader(theme, title: 'Ações rápidas', subtitle: 'Selecione a operação para preencher o formulário com o contexto adequado.', icon: Icons.bolt_outlined),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 720 ? constraints.maxWidth : ((constraints.maxWidth - 32) / 3).clamp(220.0, 320.0);
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: cards.map((item) => SizedBox(width: width, child: _operationCard(theme, item))).toList(),
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
                label: Text(_mostrarPainelFechamento ? 'Ocultar fechamento' : 'Preparar fechamento'),
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
    return Material(
      color: selected ? item.cor.withOpacity(.08) : theme.colorScheme.surface,
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
            border: Border.all(color: selected ? item.cor.withOpacity(.55) : theme.colorScheme.outline.withOpacity(0.12), width: selected ? 1.4 : 1),
          ),
          child: Row(
            children: <Widget>[
              Icon(item.icone, color: item.cor, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(item.descricao, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.35, fontSize: 12.6)),
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
            subtitle: _tipoSelecionado == null ? 'Escolha uma ação rápida acima para orientar o lançamento.' : 'Preencha os dados da operação ${_labelTipo(_tipoSelecionado!)}.',
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
                child: _buildDropdown<OperacaoCaixaTipo>(
                  theme,
                  value: _tipoSelecionado,
                  items: OperacaoCaixaTipo.values.where((e) => e != OperacaoCaixaTipo.fechamentoCaixa).toList(growable: false),
                  onChanged: (value) => setState(() => _tipoSelecionado = value),
                  itemLabel: _labelTipo,
                  hint: 'Selecione',
                ),
              ),
              _buildFieldBox(theme, width: 220, label: 'Valor', child: _buildTextField(theme, controller: _valorController, hint: '0,00', prefix: 'R\$ ')),
              _buildFieldBox(
                theme,
                width: 280,
                label: 'Forma relacionada',
                child: _buildDropdown<TiposRecebimento>(
                  theme,
                  value: _tipoRecebimentoSelecionado,
                  items: _tiposRecebimentoAtivosOrdenados(),
                  onChanged: (value) => setState(() => _tipoRecebimentoSelecionado = value),
                  itemLabel: (item) => _descricaoTipoRecebimentoConfigurado(item),
                  hint: 'Selecione',
                ),
              ),
              _buildFieldBox(theme, width: 240, label: 'Caixa / guichê', child: _buildReadOnlyField(theme, _sessaoAtual?.nomeCaixa ?? '--')),
              _buildFieldBox(theme, width: 260, label: 'Referência / comprovante', child: _buildTextField(theme, controller: _referenciaController, hint: 'Ex.: MOV-001')),
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
                  decoration: _inputDecoration(theme, hint: 'Descreva o motivo da movimentação com clareza.'),
                ),
              ),
              SizedBox(
                width: 300,
                child: CheckboxListTile(
                  value: _vincularVenda,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Possui vínculo com venda'),
                  subtitle: const Text('Use em estornos ou situações relacionadas a atendimento anterior.'),
                  onChanged: (value) => setState(() => _vincularVenda = value ?? false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(onPressed: _isLoading ? null : _salvarMovimento, icon: const Icon(Icons.save_outlined), label: const Text('Registrar movimentação')),
              OutlinedButton.icon(onPressed: _limparFormularioMovimento, icon: const Icon(Icons.refresh_rounded), label: const Text('Limpar formulário')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorico(ThemeData theme) {
    final movimentosVisiveis = _mostrarApenasHoje
        ? _movimentos.where((m) => _isSameDay(m.dataHoraMovimento, DateTime.now())).toList(growable: false)
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
              Expanded(child: _sectionHeader(theme, title: 'Histórico de movimentações', subtitle: '${movimentosVisiveis.length} registros visíveis.', icon: Icons.history_rounded)),
              FilterChip(label: const Text('Somente hoje'), selected: _mostrarApenasHoje, onSelected: (value) => setState(() => _mostrarApenasHoje = value)),
            ],
          ),
          const SizedBox(height: 14),
          if (movimentosVisiveis.isEmpty)
            Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: _softBox(theme), child: const Text('Nenhuma movimentação registrada após a abertura do caixa.'))
          else
            ListView.separated(
              shrinkWrap: true,
              primary: false,
              itemCount: movimentosVisiveis.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildMovimentoCard(theme, movimentosVisiveis[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildMovimentoCard(ThemeData theme, MovimentoCaixa movimento) {
    final cor = _corPorNatureza(movimento.natureza);
    final forma = _descricaoTipoRecebimentoMovimento(movimento);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.12)),
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
                decoration: BoxDecoration(color: cor.withOpacity(.10), borderRadius: BorderRadius.circular(15)),
                child: Icon(movimento.natureza.toLowerCase() == 'entrada' ? Icons.south_west_rounded : Icons.north_east_rounded, color: cor),
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
                        Text(_labelTipo(movimento.tipoMovimento), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                        _statusPill(_labelStatusMovimento(movimento.status), _corPorStatus(movimento.status)),
                        _statusPill(_labelNatureza(movimento.natureza), cor),
                        _statusPill(forma, theme.colorScheme.primary),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      movimento.observacao.isEmpty ? 'Sem observação informada.' : movimento.observacao,
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.70), height: 1.35),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: <Widget>[
                        _inlineInfo(theme, Icons.person_outline_rounded, movimento.nomeColaborador),
                        _inlineInfo(theme, Icons.payments_outlined, forma),
                        _inlineInfo(theme, Icons.receipt_long_outlined, movimento.referencia.isEmpty ? 'Sem referência' : movimento.referencia),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Column(
            crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: <Widget>[
              Text(_formatCurrency(movimento.valor), style: TextStyle(color: cor, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(_formatDateTime(movimento.dataHoraMovimento), style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12.5, fontWeight: FontWeight.w600)),
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
                    OutlinedButton(onPressed: () => _cancelarMovimento(movimento), child: const Text('Cancelar')),
                ],
              ),
            ],
          );

          return compact
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[main, const SizedBox(height: 12), actions])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Expanded(child: main), const SizedBox(width: 14), ConstrainedBox(constraints: const BoxConstraints(minWidth: 210), child: actions)]);
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
              _sectionHeader(theme, title: 'Conferência por forma', subtitle: 'Resumo pelos tipos configurados no caixa.', icon: Icons.fact_check_outlined),
              const SizedBox(height: 14),
              ..._linhasResumoPorTipoRecebimento().map((linha) => _buildResumoSecundario(linha.label, _formatCurrency(linha.valor))),
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
              _sectionHeader(theme, title: 'Checklist operacional', subtitle: 'Conferência rápida da sessão.', icon: Icons.rule_folder_outlined),
              const SizedBox(height: 14),
              _checkItem(theme, checked: _temCaixaAberto, title: 'Caixa aberto'),
              _checkItem(theme, checked: _movimentos.isNotEmpty, title: 'Movimentações registradas'),
              _checkItem(theme, checked: _movimentos.any((m) => m.status.toLowerCase() == 'pendenteconferencia'), title: 'Há pendências para conferência'),
              _checkItem(theme, checked: _mostrarPainelFechamento, title: 'Fechamento preparado'),
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
          _sectionHeader(theme, title: 'Fechamento de caixa', subtitle: 'Informe os valores apurados para comparar com o saldo esperado.', icon: Icons.task_alt_rounded),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _buildFieldBox(theme, width: 230, label: '${_labelTipoRecebimentoPorCodigo('tipo1', 'Dinheiro')} apurado', child: _buildTextField(theme, controller: _fechamentoDinheiroController, hint: _formatCurrency(resumo.totalDinheiro), prefix: 'R\$ ')),
              _buildFieldBox(theme, width: 230, label: '${_labelTipoRecebimentoPorCodigo('tipo2', 'Pix')} apurado', child: _buildTextField(theme, controller: _fechamentoPixController, hint: _formatCurrency(resumo.totalPix), prefix: 'R\$ ')),
              _buildFieldBox(theme, width: 250, label: 'Cartões apurados', child: _buildTextField(theme, controller: _fechamentoCartaoController, hint: _formatCurrency(resumo.totalCartaoCredito + resumo.totalCartaoDebito), prefix: 'R\$ ')),
              SizedBox(
                width: 280,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: _softBox(theme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Saldo esperado', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(_formatCurrency(resumo.saldoEsperado), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
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
              decoration: _inputDecoration(theme, hint: 'Detalhe divergências, conferências e observações finais.'),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(onPressed: _isLoading ? null : _fecharCaixa, icon: const Icon(Icons.task_alt_rounded), label: const Text('Concluir fechamento')),
              OutlinedButton.icon(onPressed: () => setState(() => _mostrarPainelFechamento = false), icon: const Icon(Icons.close_rounded), label: const Text('Cancelar fechamento')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, {required String title, required String subtitle, required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumoSecundario(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _checkItem(ThemeData theme, {required bool checked, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Icon(checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 19, color: checked ? const Color(0xff16a34a) : theme.colorScheme.outline),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(.18))),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }

  Widget _inlineInfo(ThemeData theme, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12.8, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _buildFieldBox(ThemeData theme, {required double width, required String label, required Widget child}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        child,
      ],
    );
    return width == double.infinity ? SizedBox(width: double.infinity, child: content) : SizedBox(width: width, child: content);
  }

  Widget _buildReadOnlyField(ThemeData theme, String value) {
    return Container(
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _softBox(theme, radius: 16),
      child: Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildTextField(ThemeData theme, {required TextEditingController controller, required String hint, String? prefix}) {
    return TextField(controller: controller, decoration: _inputDecoration(theme, hint: hint, prefixText: prefix));
  }

  Widget _buildDropdown<T>(
    ThemeData theme, {
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T item) itemLabel,
    String? hint,
  }) {
    return DropdownButtonFormField<T>(
      value: items.contains(value) ? value : null,
      isExpanded: true,
      decoration: _inputDecoration(theme, hint: hint),
      items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(itemLabel(item), overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(ThemeData theme, {required String? hint, String? prefixText}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.13)),
      boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(0.035), blurRadius: 12, offset: const Offset(0, 6))],
    );
  }

  BoxDecoration _softBox(ThemeData theme, {double radius = 18}) {
    return BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.42),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.10)),
    );
  }

  List<TiposRecebimento> _tiposRecebimentoAtivosOrdenados() {
    return _tiposRecebimento.where((item) => item.ativo).toList(growable: false)
      ..sort((a, b) => a.ordemExibicao.compareTo(b.ordemExibicao));
  }

  String _descricaoTipoRecebimentoConfigurado(TiposRecebimento tipo) {
    final descricao = tipo.descricaoExibicao.trim();
    return descricao.isNotEmpty ? descricao : _labelTipoRecebimentoPorCodigo(tipo.codigoTipo, tipo.codigoTipo);
  }

  String _descricaoTipoRecebimentoMovimento(MovimentoCaixa movimento) {
    final descricao = movimento.descricaoTipoRecebimento.trim();
    if (descricao.isNotEmpty) return descricao;
    return _labelTipoRecebimentoPorCodigo(
      movimento.codigoTipoRecebimento,
      movimento.descricao.trim().isNotEmpty ? movimento.descricao.trim() : 'Forma não informada',
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
        .map((tipo) => _ResumoTipoRecebimentoData(
              _descricaoTipoRecebimentoConfigurado(tipo),
              _valorResumoPorCodigoTipo(tipo.codigoTipo),
            ))
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um caixa / guichê.')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caixa aberto com sucesso.')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione o tipo da operação.')));
      return;
    }
    if (_tipoRecebimentoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione a forma relacionada.')));
      return;
    }

    final valor = _parseCurrency(_valorController.text);
    if (valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe um valor válido.')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Movimentação registrada com sucesso.')));
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

    final resumo = _resumo;
    final dinheiro = _fechamentoDinheiroController.text.trim().isEmpty
        ? (resumo?.totalDinheiro ?? 0)
        : _parseCurrency(_fechamentoDinheiroController.text);
    final pix = _fechamentoPixController.text.trim().isEmpty
        ? (resumo?.totalPix ?? 0)
        : _parseCurrency(_fechamentoPixController.text);
    final cartao = _fechamentoCartaoController.text.trim().isEmpty
        ? ((resumo?.totalCartaoCredito ?? 0) + (resumo?.totalCartaoDebito ?? 0))
        : _parseCurrency(_fechamentoCartaoController.text);

    setState(() => _isLoading = true);
    try {
      await _caixaService.fecharCaixa(
        FecharCaixaRequest(
          idSessaoCaixa: _sessaoAtual!.idSessaoCaixa,
          valorDinheiroApurado: dinheiro,
          valorPixApurado: pix,
          valorCartaoApurado: cartao,
          observacaoFechamento: _fechamentoObservacaoController.text.trim(),
        ),
      );
      await _carregarDadosIniciais();
      if (!mounted) return;
      setState(() {
        _mostrarPainelFechamento = false;
        _fechamentoDinheiroController.clear();
        _fechamentoPixController.clear();
        _fechamentoCartaoController.clear();
        _fechamentoObservacaoController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caixa fechado com sucesso.')));
    } catch (e) {
      _mostrarErro('Erro ao fechar caixa: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmarEncerramentoSessao() async {
    if (!_temCaixaAberto) {
      _mostrarAvisoCaixaNaoAberto();
      return;
    }

    final confirmou = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Encerrar sessão?'),
            content: const Text('Esta ação encerrará o caixa atual. Você ainda poderá consultar o histórico da sessão.'),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Encerrar')),
            ],
          ),
        ) ??
        false;

    if (!confirmou) return;

    setState(() => _isLoading = true);
    try {
      await _caixaService.encerrarSessao();
      await _carregarDadosIniciais();
      if (!mounted) return;
      setState(() => _mostrarPainelFechamento = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sessão encerrada.')));
    } catch (e) {
      _mostrarErro('Erro ao encerrar sessão: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelarMovimento(MovimentoCaixa movimento) async {
    final forma = _descricaoTipoRecebimentoMovimento(movimento);
    final confirmou = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Cancelar movimentação?'),
            content: Text('Deseja cancelar a operação ${_labelTipo(movimento.tipoMovimento)} em $forma no valor de ${_formatCurrency(movimento.valor)}?'),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancelar operação')),
            ],
          ),
        ) ??
        false;

    if (!confirmou) return;

    setState(() => _isLoading = true);
    try {
      await _caixaService.cancelarMovimentacao(movimento.idMovimento);
      await _carregarMovimentosEResumo(_sessaoAtual!.idSessaoCaixa);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Movimentação cancelada.')));
    } catch (e) {
      _mostrarErro('Erro ao cancelar movimentação: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _corPorNatureza(String? natureza) {
    if (natureza == null) return const Color(0xff7a8394);
    return natureza.toLowerCase() == 'entrada' ? const Color(0xff15803d) : const Color(0xffb91c1c);
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
      return '${negative ? '-' : ''}R\$ ${buffer.toString()},$decimal';
    }
  }

  double _parseCurrency(String text) {
    final cleaned = text.replaceAll('R\$', '').replaceAll('.', '').replaceAll(' ', '').replaceAll(',', '.').trim();
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
      return dateTime.year == other.year && dateTime.month == other.month && dateTime.day == other.day;
    } catch (_) {
      return false;
    }
  }
}

class _SairDaTelaIntent extends Intent {
  const _SairDaTelaIntent();
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
