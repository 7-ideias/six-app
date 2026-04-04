import 'package:appplanilha/presentation/screens/agenda_financeira_web.dart';
import 'package:appplanilha/presentation/screens/configuracoes_six_web_page.dart';
import 'package:appplanilha/presentation/screens/operacoes_caixa_web_page.dart';
import 'package:appplanilha/presentation/screens/ordem_servico_web.dart';
import 'package:appplanilha/presentation/screens/pdv_page_web_orcamento.dart';
import 'package:appplanilha/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:appplanilha/presentation/screens/recebimento_pagamento_web.dart';
import 'package:appplanilha/providers/telainicial_web_provider.dart';
import 'package:appplanilha/sub_painel_cadastro_produto.dart';
import 'package:appplanilha/sub_painel_configuracoes.dart';
import 'package:appplanilha/domain/models/pdv_visual_theme.dart';
import 'package:appplanilha/domain/services/aparencia/pdv_visual_theme_resolver.dart';
import 'package:appplanilha/design_system/helpers/six_theme_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/models/produto_model.dart';
import 'core/di/operacao_module.dart';
import 'core/services/websocket_service.dart';
import 'design_system/themes/zebra_list_item.dart';
import 'domain/services/operacao/operacao_service.dart';
import 'top_navigation_bar.dart';

class PDVWeb extends StatefulWidget {
  const PDVWeb({super.key});

  @override
  State<PDVWeb> createState() => _PDVWebState();
}

enum ModuloCentralPDV {
  seletor,
  vendas,
  orcamento,
  operacoesCaixa,
  ordemServico,
  agendaFinanceira,
  configuracoes,
}

class _PDVWebState extends State<PDVWeb> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _ultimoEventoWebSocket;
  final List<Map<String, dynamic>> _notificacoes = <Map<String, dynamic>>[];
  int _quantidadeNotificacoesNaoLidas = 0;

  late final AnimationController _bellAnimationController;
  late final Animation<double> _bellRotationAnimation;

  final SixThemeResolver _themeResolver = SixThemeResolver();
  late PdvVisualTheme _pdvTheme;

  final OperacaoService _operacaoService = OperacaoModule.operacaoService;

  bool _mostrarDashboardLateral = true;
  ModuloCentralPDV _moduloAtual = ModuloCentralPDV.seletor;

  final List<Map<String, dynamic>> _produtosSelecionados = <Map<String, dynamic>>[];
  final Set<String> _formasSelecionadas = <String>{};

  final TextEditingController _codigoBarrasController = TextEditingController();
  final TextEditingController _itensTotalController = TextEditingController(text: '0');
  final TextEditingController _clienteIdentificadoController = TextEditingController();

  final FocusNode _atalhosFocusNode = FocusNode(debugLabel: 'pdv-shortcuts');
  final FocusNode _codigoBarrasFocusNode = FocusNode(debugLabel: 'barcode-field');

  final ScrollController _notificacoesScrollController = ScrollController();
  final ScrollController _sidebarScrollController = ScrollController();
  final ScrollController _seletorScrollController = ScrollController();
  final ScrollController _gradeItensScrollController = ScrollController();
  final ScrollController _resumoVendaScrollController = ScrollController();
  final ScrollController _areaVendaScrollController = ScrollController();

  void _onThemeChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _pdvTheme = PdvVisualThemeResolver.resolve(_themeResolver.paleta);
    });
  }

  @override
  void initState() {
    super.initState();
    _pdvTheme = PdvVisualThemeResolver.resolve(_themeResolver.paleta);
    _themeResolver.addListener(_onThemeChanged);
    _atualizarCamposDerivados();

    _bellAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _bellRotationAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0, end: -0.10), weight: 1),
      TweenSequenceItem<double>(tween: Tween<double>(begin: -0.10, end: 0.10), weight: 2),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.10, end: -0.08), weight: 2),
      TweenSequenceItem<double>(tween: Tween<double>(begin: -0.08, end: 0.08), weight: 2),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0.08, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _bellAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _configurarWebSocket();
  }

  @override
  void dispose() {
    _themeResolver.removeListener(_onThemeChanged);
    onMensagemRecebida = null;
    disconnectStomp();
    _bellAnimationController.dispose();
    _atalhosFocusNode.dispose();
    _codigoBarrasFocusNode.dispose();
    _codigoBarrasController.dispose();
    _itensTotalController.dispose();
    _clienteIdentificadoController.dispose();
    _notificacoesScrollController.dispose();
    _sidebarScrollController.dispose();
    _seletorScrollController.dispose();
    _gradeItensScrollController.dispose();
    _resumoVendaScrollController.dispose();
    _areaVendaScrollController.dispose();
    super.dispose();
  }

  void _configurarWebSocket() {
    onMensagemRecebida = (json) {
      if (!mounted) {
        return;
      }

      final Map<String, dynamic> notificacao = <String, dynamic>{
        ...json,
        'recebidoEm': DateTime.now().toIso8601String(),
      };

      setState(() {
        _ultimoEventoWebSocket = notificacao;
        _notificacoes.insert(0, notificacao);
        _quantidadeNotificacoesNaoLidas = (_quantidadeNotificacoesNaoLidas + 1).clamp(0, 9);
      });

      _bellAnimationController.forward(from: 0);

      final String mensagem = json['mensagem']?.toString() ?? 'Evento recebido do backend';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
        ),
      );
    };

    connectStomp();
  }

  String _badgeNotificacaoTexto() {
    if (_quantidadeNotificacoesNaoLidas <= 0) {
      return '';
    }

    if (_quantidadeNotificacoesNaoLidas > 9) {
      return '+9';
    }

    return '+$_quantidadeNotificacoesNaoLidas';
  }

  void _abrirPainelNotificacoes() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 560,
            constraints: const BoxConstraints(maxHeight: 640),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.notifications_active_rounded, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Notificações',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _notificacoes.clear();
                          _quantidadeNotificacoesNaoLidas = 0;
                          _ultimoEventoWebSocket = null;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Limpar'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _notificacoes.isEmpty
                      ? Center(
                    child: Text(
                      'Nenhuma notificação recebida.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                      : ListView.separated(
                    controller: _notificacoesScrollController,
                    primary: false,
                    itemCount: _notificacoes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final Map<String, dynamic> item = _notificacoes[index];
                      final String ordemId = item['ordemId']?.toString() ?? '-';
                      final String status = item['status']?.toString() ?? '-';
                      final String mensagem = item['mensagem']?.toString() ?? 'Sem mensagem';
                      final String recebidoEm = item['recebidoEm']?.toString() ?? '';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.campaign_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    mensagem,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Ordem: $ordemId'),
                            const SizedBox(height: 4),
                            Text('Status: $status'),
                            if (recebidoEm.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(
                                'Recebido em: $recebidoEm',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _quantidadeNotificacoesNaoLidas = 0;
      });
    });
  }

  Widget _buildNotificationBellButton() {
    final bool temNaoLidas = _quantidadeNotificacoesNaoLidas > 0;
    final String badgeTexto = _badgeNotificacaoTexto();

    return AnimatedBuilder(
      animation: _bellRotationAnimation,
      builder: (BuildContext context, Widget? child) {
        return Transform.rotate(
          angle: _bellRotationAnimation.value,
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _abrirPainelNotificacoes,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _pdvTheme.backgroundSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _pdvTheme.cardBorder),
                ),
                child: Icon(
                  temNaoLidas ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                  color: _pdvTheme.iconColor,
                ),
              ),
            ),
          ),
          if (temNaoLidas)
            Positioned(
              top: -6,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _pdvTheme.warningColor,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: _pdvTheme.warningColor.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  badgeTexto,
                  style: TextStyle(
                    color: _pdvTheme.badgeText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _abrirSelecaoProdutoWeb() async {
    final ProdutoModel? result = await showDialog<ProdutoModel>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.80,
            height: MediaQuery.of(context).size.height * 0.80,
            child: SubPainelWebProdutoLista(isSelecao: true),
          ),
        );
      },
    );

    if (result != null) {
      _adicionarProdutoSelecionado(result);
    }
  }

  void _iniciarVenda() {
    setState(() {
      _moduloAtual = ModuloCentralPDV.vendas;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focarCodigoBarras();
      }
    });
  }

  Future<void> _confirmarCancelamentoVenda() async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar venda'),
          content: const Text('Deseja realmente cancelar a venda atual?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim, cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      _cancelarVenda();
    }
  }

  void _cancelarVenda() {
    setState(() {
      _produtosSelecionados.clear();
      _formasSelecionadas.clear();
      _codigoBarrasController.clear();
      _itensTotalController.text = '0';
      _clienteIdentificadoController.clear();
      _moduloAtual = ModuloCentralPDV.seletor;
    });
  }

  void _adicionarProdutoSelecionado(ProdutoModel produto) {
    setState(() {
      final int indexExistente = _produtosSelecionados.indexWhere(
            (Map<String, dynamic> item) => _mesmoProduto(item, produto),
      );

      if (indexExistente >= 0) {
        _produtosSelecionados[indexExistente]['quantidade'] = (_produtosSelecionados[indexExistente]['quantidade'] ?? 1) + 1;
      } else {
        _produtosSelecionados.add(<String, dynamic>{
          'id': _extrairIdProduto(produto),
          'codigo': produto.codigoDeBarras,
          'nome': produto.nomeProduto,
          'preco': produto.precoVenda,
          'quantidade': 1,
          'produtoOriginal': produto,
        });
      }

      _atualizarCamposDerivados();
    });
  }

  bool _mesmoProduto(Map<String, dynamic> item, ProdutoModel produto) {
    final dynamic idItem = item['id'];
    final dynamic idProduto = _extrairIdProduto(produto);

    if (idItem != null && idProduto != null) {
      return idItem == idProduto;
    }

    final String? codigoItem = item['codigo']?.toString();
    final String? codigoProduto = produto.codigoDeBarras.toString();

    if (codigoItem != null && codigoItem.isNotEmpty && codigoProduto!.isNotEmpty) {
      return codigoItem == codigoProduto;
    }

    return item['nome'] == produto.nomeProduto;
  }

  dynamic _extrairIdProduto(ProdutoModel produto) {
    final dynamic p = produto;
    return p.id ?? p.uuid ?? p.idUnico ?? p.codigo;
  }

  void _alterarQuantidade(Map<String, dynamic> produto, int delta) {
    setState(() {
      final int quantidadeAtual = (produto['quantidade'] ?? 1) as int;
      final int novaQuantidade = quantidadeAtual + delta;

      if (novaQuantidade <= 0) {
        _produtosSelecionados.remove(produto);
      } else {
        produto['quantidade'] = novaQuantidade;
      }

      _atualizarCamposDerivados();
    });
  }

  void _removerProduto(Map<String, dynamic> produto) {
    setState(() {
      _produtosSelecionados.remove(produto);
      _atualizarCamposDerivados();
    });
  }

  void _atualizarCamposDerivados() {
    _itensTotalController.text = _calcularQuantidadeItens().toString();
  }

  double _calcularTotal() {
    return _produtosSelecionados.fold<double>(
      0,
          (double soma, Map<String, dynamic> item) {
        return soma + (((item['preco'] ?? 0) as num).toDouble() * ((item['quantidade'] ?? 1) as int));
      },
    );
  }

  int _calcularQuantidadeItens() {
    return _produtosSelecionados.fold<int>(
      0,
          (int soma, Map<String, dynamic> item) => soma + ((item['quantidade'] ?? 1) as int),
    );
  }

  double _calcularSubtotal(Map<String, dynamic> produto) {
    final double preco = ((produto['preco'] ?? 0) as num).toDouble();
    final int quantidade = (produto['quantidade'] ?? 1) as int;
    return preco * quantidade;
  }

  void _mostrarDialogMensagem(String titulo, String mensagem) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensagem),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _focarCodigoBarras() {
    _codigoBarrasFocusNode.requestFocus();
  }

  Future<void> _abrirDialogClienteRapido() async {
    final TextEditingController controller = TextEditingController(
      text: _clienteIdentificadoController.text,
    );

    final String? cliente = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Identificar cliente'),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nome ou identificação do cliente',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (cliente != null) {
      setState(() {
        _clienteIdentificadoController.text = cliente;
      });
    }
  }

  void _abrirOrcamento() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OrcamentoWeb(),
      ),
    );
  }

  void _adicionarServicoRapido() {
    _mostrarDialogMensagem(
      'Adicionar serviço',
      'Aqui você pode plugar a abertura rápida de um serviço e incluir o item na venda.',
    );
  }

  KeyEventResult _handleAtalhoPdv(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (_moduloAtual != ModuloCentralPDV.vendas) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.f2) {
      _abrirSelecaoProdutoWeb();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.f4) {
      _abrirDialogClienteRapido();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.f8 && _produtosSelecionados.isNotEmpty) {
      _abrirTelaRecebimento();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _confirmarCancelamentoVenda();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _pausarVenda() {
    _mostrarDialogMensagem(
      'Pausar venda',
      'A ideia aqui é deixar a venda aberta para continuar o atendimento depois.',
    );
  }

  void _abrirTelaRecebimento() {
    if (_produtosSelecionados.isEmpty) {
      _mostrarDialogMensagem(
        'Venda vazia',
        'Adicione pelo menos um item antes de finalizar.',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecebimentoPagamentoWeb(
          valorTotalVenda: _calcularTotal(),
          itensResumo: _montarItensResumoPagamento(),
          clienteNome: _clienteIdentificadoController.text.trim(),
          numeroVenda: '',
          idColaborador: 'idUnicoDoColaborador',
          nomeColaborador: 'Nome do colaborador',
          operacaoService: _operacaoService,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _montarItensResumoPagamento() {
    return _produtosSelecionados.map((Map<String, dynamic> produto) {
      final int quantidade = (produto['quantidade'] ?? 1) as int;
      final double precoUnitario = ((produto['preco'] ?? 0) as num).toDouble();

      return <String, dynamic>{
        'id': produto['id'],
        'codigo': produto['codigo'],
        'nome': produto['nome'] ?? '',
        'quantidade': quantidade,
        'valor': precoUnitario,
        'subtotal': precoUnitario * quantidade,
        'ehServico': false,
      };
    }).toList();
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2)}';
  }

  String _clienteAtualLabel() {
    final String nome = _clienteIdentificadoController.text.trim();
    return nome.isEmpty ? 'Não identificado' : nome;
  }

  List<Map<String, String>> get _dashboardData => <Map<String, String>>[
    <String, String>{
      'title': 'Vendas Abertas',
      'count': TelaInicialWebProvider().telaInicialWeb?.totalVendasAbertas.toString() ?? '0',
    },
    <String, String>{
      'title': 'Ordens Abertas',
      'count': TelaInicialWebProvider().telaInicialWeb?.totalOrdensDeServicoAbertas.toString() ?? '0',
    },
    <String, String>{'title': 'OTs em revisão', 'count': '33'},
    <String, String>{'title': 'OTs em processo', 'count': '27'},
    <String, String>{'title': 'OTs finalizadas', 'count': '94'},
    <String, String>{'title': 'OTs atrasadas', 'count': '10'},
  ];

  Widget _buildConteudoCentral(double total) {
    switch (_moduloAtual) {
      case ModuloCentralPDV.vendas:
        return _buildAreaVenda(total);
      case ModuloCentralPDV.operacoesCaixa:
        return Expanded(
          child: OperacoesCaixaWebPage(
            embedded: true,
            onBack: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.seletor;
              });
            },
          ),
        );
      case ModuloCentralPDV.orcamento:
        return const Expanded(child: OrcamentoWeb());
      case ModuloCentralPDV.ordemServico:
        return const Expanded(child: OrdemServicoWeb());
      case ModuloCentralPDV.agendaFinanceira:
        return const Expanded(child: AgendaFinanceiraWeb());
      case ModuloCentralPDV.configuracoes:
        return Expanded(
          child: ConfiguracoesSixWebPage(
            embedded: true,
            onBack: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.seletor;
              });
            },
          ),
        );
      case ModuloCentralPDV.seletor:
        return _buildSeletorModoOperacao();
    }
  }

  Widget _buildModoOperacaoButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    String badge;
    String descricao;

    switch (label) {
      case 'Vendas':
        badge = 'Fluxo principal';
        descricao = 'Atendimento rápido no caixa, inclusão de itens e fechamento da venda.';
        break;
      case 'Orçamento':
        badge = 'Assistência comercial';
        descricao = 'Monte propostas com organização, clareza e continuidade do atendimento.';
        break;
      default:
        badge = 'Operação interna';
        descricao = 'Controle operacional e financeiro da rotina do balcão.';
    }

    return SizedBox(
      width: 300,
      height: 304,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              color: _pdvTheme.cardBackground,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _pdvTheme.cardBorder),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _pdvTheme.cardShadow,
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _pdvTheme.badgeBackground.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _pdvTheme.badgeBackground.withOpacity(0.20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              label == 'Vendas'
                                  ? Icons.flash_on_rounded
                                  : label == 'Orçamento'
                                  ? Icons.auto_awesome
                                  : Icons.settings_outlined,
                              size: 16,
                              color: _pdvTheme.iconColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              badge,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _pdvTheme.iconColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.north_east_rounded,
                        size: 22,
                        color: _pdvTheme.iconColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _pdvTheme.iconColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _pdvTheme.iconColor.withOpacity(0.20),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 34,
                      color: _pdvTheme.iconColor,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _pdvTheme.iconColor,
                      height: 1.10,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Text(
                      descricao,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: _pdvTheme.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String count) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: _pdvTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: _pdvTheme.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _pdvTheme.iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  count,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _pdvTheme.iconColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _pdvTheme.primaryText,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Cockpit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _pdvTheme.iconColor,
              ),
            ),
          ),
          Tooltip(
            message: 'Ocultar painel',
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                setState(() {
                  _mostrarDashboardLateral = false;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _pdvTheme.backgroundSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _pdvTheme.cardBorder),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: _pdvTheme.iconColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoSidebar() {
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 14),
      decoration: BoxDecoration(
        color: _pdvTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildResumoSidebarHeader(),
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  _pdvTheme.iconColor.withOpacity(0.08),
                  _pdvTheme.backgroundPage.withOpacity(0.70),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _pdvTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Painel operacional',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _pdvTheme.iconColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Visão rápida de vendas, ordens e indicadores para dar ritmo à operação.',
                  style: TextStyle(
                    fontSize: 14,
                    color: _pdvTheme.secondaryText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: _sidebarScrollController,
              primary: false,
              padding: EdgeInsets.zero,
              itemCount: _dashboardData.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                return _buildDashboardCard(
                  _dashboardData[index]['title'] ?? '',
                  _dashboardData[index]['count'] ?? '0',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoSidebarCollapsed() {
    return Padding(
      padding: const EdgeInsets.only(top: 14, right: 12),
      child: Tooltip(
        message: 'Mostrar painel',
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _mostrarDashboardLateral = true;
            });
          },
          child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: _pdvTheme.backgroundSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _pdvTheme.cardBorder),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _pdvTheme.cardShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Icon(Icons.dashboard_customize_outlined, color: _pdvTheme.iconColor),
                const SizedBox(height: 10),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Cockpit',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _pdvTheme.iconColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Icon(Icons.chevron_right_rounded, color: _pdvTheme.iconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardUltimoEvento() {
    if (_ultimoEventoWebSocket == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _pdvTheme.eventCardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _pdvTheme.eventCardBorder),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.notifications_none_rounded, color: _pdvTheme.iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nenhum evento recebido do backend até agora.',
                style: TextStyle(
                  color: _pdvTheme.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final String ordemId = _ultimoEventoWebSocket!['ordemId']?.toString() ?? '-';
    final String status = _ultimoEventoWebSocket!['status']?.toString() ?? '-';
    final String mensagem = _ultimoEventoWebSocket!['mensagem']?.toString() ?? 'Sem mensagem';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _pdvTheme.highlightColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.notifications_active_rounded, color: _pdvTheme.highlightColor),
              const SizedBox(width: 10),
              Text(
                'Último evento do backend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _pdvTheme.highlightColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ordem: $ordemId',
            style: TextStyle(fontWeight: FontWeight.w700, color: _pdvTheme.primaryText),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: $status',
            style: TextStyle(fontWeight: FontWeight.w700, color: _pdvTheme.primaryText),
          ),
          const SizedBox(height: 8),
          Text(mensagem, style: TextStyle(color: _pdvTheme.primaryText)),
        ],
      ),
    );
  }

  Widget _buildSeletorModoOperacao() {
    return Expanded(
      child: SingleChildScrollView(
        controller: _seletorScrollController,
        primary: false,
        child: Column(
          children: <Widget>[
            _buildCardUltimoEvento(),
            const SizedBox(height: 24),
            Center(
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  _buildModoOperacaoButton(
                    icon: Icons.point_of_sale,
                    label: 'Vendas',
                    onPressed: _iniciarVenda,
                  ),
                  _buildModoOperacaoButton(
                    icon: Icons.request_quote,
                    label: 'Orçamento',
                    onPressed: _abrirOrcamento,
                  ),
                  _buildModoOperacaoButton(
                    icon: Icons.account_balance_wallet,
                    label: 'Operações de caixa',
                    onPressed: () {
                      setState(() {
                        _moduloAtual = ModuloCentralPDV.operacoesCaixa;
                      });
                    },
                  ),
                  _buildModoOperacaoButton(
                    icon: Icons.build_circle_outlined,
                    label: 'Ordem de Serviço',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const OrdemServicoWeb(),
                        ),
                      );
                    },
                  ),
                  _buildModoOperacaoButton(
                    icon: Icons.monetization_on,
                    label: labelAgendaFinanceira(),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AgendaFinanceiraWeb(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String labelAgendaFinanceira() => 'Agenda Financeira';

  Widget _buildVendaHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            _pdvTheme.highlightColor.withOpacity(0.10),
            _pdvTheme.backgroundSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _pdvTheme.iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.point_of_sale_rounded,
              size: 32,
              color: _pdvTheme.iconColor,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 320, maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Frente de caixa',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _pdvTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cockpit operacional para atendimento rápido, leitura de itens e fechamento sem fricção.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.40,
                    color: _pdvTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          _buildTopBadge('F2 Buscar produto', Icons.search_rounded),
          _buildTopBadge('F4 Identificar cliente', Icons.person_search_rounded),
          _buildTopBadge('F8 Receber', Icons.payments_rounded),
          _buildTopBadge('ESC Cancelar', Icons.close_rounded),
        ],
      ),
    );
  }

  Widget _buildTopBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _pdvTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: _pdvTheme.iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _pdvTheme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    bool destaque = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: destaque ? _pdvTheme.iconColor : _pdvTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: destaque ? _pdvTheme.iconColor : _pdvTheme.cardBorder,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _pdvTheme.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: destaque ? Colors.white.withOpacity(0.18) : _pdvTheme.iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: destaque ? Colors.white : _pdvTheme.iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: destaque ? Colors.white.withOpacity(0.85) : _pdvTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: destaque ? Colors.white : _pdvTheme.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraOperacional() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _pdvTheme.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _pdvTheme.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Faixa operacional',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _pdvTheme.primaryText,
                  ),
                ),
              ),
              Text(
                'Foco: velocidade, clareza e fechamento seguro',
                style: TextStyle(
                  color: _pdvTheme.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _pdvTheme.backgroundPage,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _pdvTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Leitura / busca de item',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _pdvTheme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _codigoBarrasController,
                              focusNode: _codigoBarrasFocusNode,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Passe um item ou digite um código',
                                labelText: 'Código de barras',
                                prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                                suffixIcon: IconButton(
                                  tooltip: 'Focar leitura',
                                  onPressed: _focarCodigoBarras,
                                  icon: const Icon(Icons.keyboard_alt_outlined),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(color: _pdvTheme.cardBorder),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            height: 58,
                            child: OutlinedButton.icon(
                              onPressed: _abrirSelecaoProdutoWeb,
                              icon: const Icon(Icons.search_rounded),
                              label: const Text('Buscar produto'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: _pdvTheme.actionButtonBackground, width: 1.6),
                                foregroundColor: _pdvTheme.actionButtonBackground,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.shopping_bag_outlined,
                            label: 'Itens',
                            value: _itensTotalController.text,
                            destaque: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.person_outline_rounded,
                            label: 'Cliente',
                            value: _clienteAtualLabel(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.point_of_sale_outlined,
                            label: 'Caixa / sessão',
                            value: 'Sessão ativa',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.payments_outlined,
                            label: 'Total parcial',
                            value: _formatCurrency(_calcularTotal()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTabelaItens() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: _pdvTheme.backgroundPage,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          _buildHeaderCell('Produto', flex: 5),
          _buildHeaderCell('Qtd', flex: 2, alignEnd: true),
          _buildHeaderCell('Unitário', flex: 2, alignEnd: true),
          _buildHeaderCell('Subtotal', flex: 2, alignEnd: true),
          _buildHeaderCell('Ações', flex: 2, alignEnd: true),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, {required int flex, bool alignEnd = false}) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.4,
            fontWeight: FontWeight.w800,
            color: _pdvTheme.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildLinhaTabelaItem(Map<String, dynamic> produto, int index) {
    final int quantidade = (produto['quantidade'] ?? 1) as int;
    final double preco = ((produto['preco'] ?? 0) as num).toDouble();
    final double subtotal = _calcularSubtotal(produto);

    return ZebraListItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _pdvTheme.cardBorder),
          color: index.isEven ? _pdvTheme.backgroundSurface : _pdvTheme.backgroundPage,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _pdvTheme.iconColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: _pdvTheme.iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          produto['nome']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _pdvTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Código: ${produto['codigo']?.toString().isNotEmpty == true ? produto['codigo'] : '-'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _pdvTheme.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  quantidade.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _pdvTheme.primaryText,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatCurrency(preco),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _pdvTheme.primaryText,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatCurrency(subtotal),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _pdvTheme.iconColor,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 4,
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Diminuir',
                      onPressed: () => _alterarQuantidade(produto, -1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    IconButton(
                      tooltip: 'Aumentar',
                      onPressed: () => _alterarQuantidade(produto, 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    IconButton(
                      tooltip: 'Remover',
                      onPressed: () => _removerProduto(produto),
                      icon: Icon(Icons.delete_outline_rounded, color: _pdvTheme.warningColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoVazioGuiado() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget content = Container(
          constraints: const BoxConstraints(maxWidth: 760),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _pdvTheme.backgroundPage,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _pdvTheme.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  color: _pdvTheme.iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.shopping_cart_checkout_rounded,
                  size: 46,
                  color: _pdvTheme.iconColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Passe um item ou pesquise um produto',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _pdvTheme.primaryText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Quando a venda começar, esta área vira a grade operacional dos itens. Até lá, você pode disparar as ações rápidas abaixo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: _pdvTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  _buildQuickActionButton(
                    icon: Icons.search_rounded,
                    label: 'Buscar produto',
                    onPressed: _abrirSelecaoProdutoWeb,
                  ),
                  _buildQuickActionButton(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Identificar cliente',
                    onPressed: _abrirDialogClienteRapido,
                  ),
                  _buildQuickActionButton(
                    icon: Icons.build_circle_outlined,
                    label: 'Adicionar serviço',
                    onPressed: _adicionarServicoRapido,
                  ),
                  _buildQuickActionButton(
                    icon: Icons.request_quote_outlined,
                    label: 'Abrir orçamento',
                    onPressed: _abrirOrcamento,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  _buildHintChip('F2 buscar produto'),
                  _buildHintChip('F4 identificar cliente'),
                  _buildHintChip('F8 receber'),
                  _buildHintChip('ESC cancelar venda'),
                ],
              ),
            ],
          ),
        );

        return ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
          child: SingleChildScrollView(
            primary: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(child: content),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _pdvTheme.actionButtonBackground,
        side: BorderSide(color: _pdvTheme.actionButtonBackground),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget _buildHintChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _pdvTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: _pdvTheme.secondaryText,
        ),
      ),
    );
  }

  Widget _buildGradeOperacional() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Itens da venda',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _pdvTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Formato operacional com leitura rápida de produto, quantidade, preço e subtotal.',
                      style: TextStyle(
                        fontSize: 13,
                        color: _pdvTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              _buildTopBadge('${_calcularQuantidadeItens()} item(ns)', Icons.shopping_basket_outlined),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: _produtosSelecionados.isEmpty
                ? _buildEstadoVazioGuiado()
                : Column(
              children: <Widget>[
                _buildHeaderTabelaItens(),
                const SizedBox(height: 2),
                Expanded(
                  child: ListView.builder(
                    controller: _gradeItensScrollController,
                    primary: false,
                    itemCount: _produtosSelecionados.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _buildLinhaTabelaItem(_produtosSelecionados[index], index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoVendaLateral() {
    final double total = _calcularTotal();
    final int quantidadeItens = _calcularQuantidadeItens();

    Widget buildHeader() {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _pdvTheme.cardBorder)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Venda atual',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _pdvTheme.primaryText,
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _pdvTheme.successColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Em andamento',
                        style: TextStyle(
                          color: _pdvTheme.successColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildResumoInfoTile(Icons.person_outline_rounded, 'Cliente', _clienteAtualLabel()),
            const SizedBox(height: 10),
            _buildResumoInfoTile(Icons.payments_outlined, 'Pagamento', _formasSelecionadas.isEmpty ? 'Não definido' : _formasSelecionadas.join(', ')),
            const SizedBox(height: 10),
            _buildResumoInfoTile(Icons.receipt_long_outlined, 'Itens', '$quantidadeItens item(ns)'),
          ],
        ),
      );
    }

    Widget buildBody() {
      return SingleChildScrollView(
        controller: _resumoVendaScrollController,
        primary: false,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Resumo rápido',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _pdvTheme.secondaryText,
              ),
            ),
            const SizedBox(height: 12),
            if (_produtosSelecionados.isEmpty) ...<Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _pdvTheme.backgroundPage,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _pdvTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Nenhum item adicionado ainda.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _pdvTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Enquanto a venda está vazia, use este painel como atalho operacional.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.40,
                        color: _pdvTheme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        _buildMiniAction('Trocar cliente', Icons.person_search_rounded, _abrirDialogClienteRapido),
                        _buildMiniAction('Aplicar desconto', Icons.percent_rounded, () {
                          _mostrarDialogMensagem('Aplicar desconto', 'Aqui você pode conectar a regra real de desconto.');
                        }),
                        _buildMiniAction('Buscar produto', Icons.search_rounded, _abrirSelecaoProdutoWeb),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...<Widget>[
              ..._produtosSelecionados.map((Map<String, dynamic> produto) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _pdvTheme.backgroundPage,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _pdvTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        produto['nome']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _pdvTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${produto['quantidade']} x ${_formatCurrency(((produto['preco'] ?? 0) as num).toDouble())}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _pdvTheme.secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatCurrency(_calcularSubtotal(produto)),
                            style: TextStyle(
                              color: _pdvTheme.primaryText,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      );
    }

    Widget buildFooter() {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _pdvTheme.backgroundPage,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          border: Border(top: BorderSide(color: _pdvTheme.cardBorder)),
        ),
        child: Column(
          children: <Widget>[
            _buildResumoLinhaValor('Subtotal', _formatCurrency(total)),
            const SizedBox(height: 10),
            _buildResumoLinhaValor('Desconto', _formatCurrency(0)),
            const SizedBox(height: 10),
            _buildResumoLinhaValor('Acréscimo', _formatCurrency(0)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _pdvTheme.iconColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.80),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: total),
                            duration: const Duration(milliseconds: 350),
                            builder: (BuildContext context, double value, Widget? child) {
                              return Text(
                                _formatCurrency(value),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.attach_money_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _pdvTheme.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _pdvTheme.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxHeight < 560;

          if (compact) {
            return SingleChildScrollView(
              controller: _resumoVendaScrollController,
              primary: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  buildHeader(),
                  buildBody(),
                  buildFooter(),
                ],
              ),
            );
          }

          return Column(
            children: <Widget>[
              buildHeader(),
              Expanded(child: buildBody()),
              buildFooter(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumoInfoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _pdvTheme.iconColor.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: _pdvTheme.iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _pdvTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _pdvTheme.primaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAction(String label, IconData icon, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildResumoLinhaValor(String label, String valor) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _pdvTheme.secondaryText,
            ),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: _pdvTheme.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildBarraFechamento(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _pdvTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _pdvTheme.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _pdvTheme.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: <Widget>[
          Wrap(
            spacing: 18,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Barra de fechamento',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _pdvTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: total),
                    duration: const Duration(milliseconds: 350),
                    builder: (BuildContext context, double value, Widget? child) {
                      return Text(
                        _formatCurrency(value),
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: _pdvTheme.iconColor,
                        ),
                      );
                    },
                  ),
                ],
              ),
              _buildFooterInfoCard('Subtotal', _formatCurrency(total)),
              _buildFooterInfoCard('Desconto', _formatCurrency(0)),
              _buildFooterInfoCard('Itens', '${_calcularQuantidadeItens()}'),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _pausarVenda,
                icon: const Icon(Icons.pause_circle_outline_rounded),
                label: const Text('Pausar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(150, 54),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  side: BorderSide(color: _pdvTheme.actionButtonBackground, width: 1.5),
                  foregroundColor: _pdvTheme.actionButtonBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _produtosSelecionados.isEmpty ? null : _abrirTelaRecebimento,
                icon: const Icon(Icons.payments_rounded),
                label: const Text('Receber'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(170, 54),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  backgroundColor: _pdvTheme.actionButtonBackground,
                  foregroundColor: _pdvTheme.actionButtonForeground,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _confirmarCancelamentoVenda,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 54),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  side: BorderSide(color: _pdvTheme.warningColor, width: 1.5),
                  foregroundColor: _pdvTheme.warningColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _pdvTheme.backgroundPage,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _pdvTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: _pdvTheme.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: _pdvTheme.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaVenda(double total) {
    Widget buildScrollableContent() {
      return Column(
        children: <Widget>[
          _buildVendaHero(),
          const SizedBox(height: 18),
          _buildBarraOperacional(),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  flex: 7,
                  child: _buildGradeOperacional(),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 380,
                  child: _buildResumoVendaLateral(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildBarraFechamento(total),
        ],
      );
    }

    return Expanded(
      child: Focus(
        autofocus: true,
        focusNode: _atalhosFocusNode,
        onKeyEvent: _handleAtalhoPdv,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compactHeight = constraints.maxHeight < 760;
            final bool compactWidth = constraints.maxWidth < 1360;

            if (compactHeight || compactWidth) {
              return ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  controller: _areaVendaScrollController,
                  primary: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: compactHeight ? 920 : constraints.maxHeight),
                    child: Column(
                      children: <Widget>[
                        _buildVendaHero(),
                        const SizedBox(height: 18),
                        _buildBarraOperacional(),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: compactHeight ? 560 : constraints.maxHeight - 280,
                          child: compactWidth
                              ? Column(
                            children: <Widget>[
                              Expanded(child: _buildGradeOperacional()),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 420,
                                child: _buildResumoVendaLateral(),
                              ),
                            ],
                          )
                              : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                flex: 7,
                                child: _buildGradeOperacional(),
                              ),
                              const SizedBox(width: 18),
                              SizedBox(
                                width: 380,
                                child: _buildResumoVendaLateral(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildBarraFechamento(total),
                      ],
                    ),
                  ),
                ),
              );
            }

            return buildScrollableContent();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double total = _calcularTotal();

    return Scaffold(
      backgroundColor: _pdvTheme.backgroundPage,
      appBar: TopNavigationBar(
        items: <TopNavItemData>[
          TopNavItemData(
            title: 'Início',
            subItems: const <String>['Preferências do Sistema', 'Painel Administrativo'],
            onSelect: (String value) {
              if (value == 'Painel Administrativo') {
                showSubPainelConfiguracoes(context, 'Configurações');
              }
            },
          ),
          const TopNavItemData(
            title: 'Permitir',
            subItems: <String>['Gerenciar Permissões', 'Alterar Configurações'],
          ),
          TopNavItemData(
            title: 'Cadastros',
            subItems: const <String>['Clientes', 'Produtos', 'Fornecedores', 'Produtos List'],
            onSelect: (String value) {
              if (value == 'Produtos') {
                showSubPainelCadastroProduto(context, 'Cadastro de Produtos');
              }

              if (value == 'Produtos List') {
                _abrirSelecaoProdutoWeb();
              }
            },
          ),
          TopNavItemData(
            title: 'Configurações',
            subItems: const <String>['Sistema', 'Usuários', 'Preferências do Six'],
            onSelect: (String value) {
              if (value == 'Preferências do Six') {
                setState(() {
                  _moduloAtual = ModuloCentralPDV.configuracoes;
                });
              }
            },
          ),
          const TopNavItemData(
            title: 'Relatórios',
            subItems: <String>['Vendas', 'Estoque', 'Financeiro'],
          ),
          const TopNavItemData(
            title: 'Executar',
            subItems: <String>['Processar Pagamentos', 'Fechar Caixa'],
          ),
          const TopNavItemData(
            title: 'Automações',
            subItems: <String>['Tarefas Agendadas'],
          ),
          const TopNavItemData(
            title: 'Ajuda',
            subItems: <String>['Suporte', 'Sobre'],
          ),
        ],
        notificationWidget: _buildNotificationBellButton(),
        onNotificationPressed: _abrirPainelNotificacoes,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (_mostrarDashboardLateral) ...<Widget>[
              _buildResumoSidebar(),
              const SizedBox(width: 20),
            ] else ...<Widget>[
              _buildResumoSidebarCollapsed(),
            ],
            Expanded(
              child: Card(
                elevation: 6,
                color: _pdvTheme.backgroundSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(color: _pdvTheme.cardBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: <Widget>[
                      _buildConteudoCentral(total),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
