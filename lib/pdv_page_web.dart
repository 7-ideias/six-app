import 'dart:async';

import 'package:sixpos/presentation/screens/agenda_financeira_web.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_lista_web_page.dart';
import 'package:sixpos/presentation/screens/colaboradores_usuario_list_page.dart';
import 'package:sixpos/presentation/screens/clientes_usuario_list_page.dart';
import 'package:sixpos/presentation/screens/configuracoes_six_web_page.dart';
import 'package:sixpos/presentation/screens/meu_perfil_web_screen.dart';
import 'package:sixpos/presentation/screens/operacoes_caixa_web_page.dart';
import 'package:sixpos/presentation/screens/ordem_servico_web.dart';
import 'package:sixpos/presentation/screens/pdv_cliente_identificacao_dialog.dart';
import 'package:sixpos/presentation/screens/pdv_page_web_orcamento.dart';
import 'package:sixpos/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:sixpos/presentation/screens/categorias_produtos_servicos_web_page.dart';
import 'package:sixpos/presentation/screens/recebimento_pagamento_web.dart';
import 'package:sixpos/sub_painel_cadastro_cliente.dart';
import 'package:sixpos/sub_painel_cadastro_produto.dart';
import 'package:sixpos/sub_painel_configuracoes.dart';
import 'package:sixpos/domain/models/pdv_visual_theme.dart';
import 'package:sixpos/domain/services/aparencia/pdv_visual_theme_resolver.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/sub_painel_cadastro_colaborador.dart';

import 'data/models/cliente_usuario_model.dart';
import 'data/models/produto_model.dart';
import 'data/models/operacao_models.dart';
import 'core/di/operacao_module.dart';
import 'core/services/auth_service.dart';
import 'core/services/websocket_service.dart';
import 'presentation/screens/login_page_web.dart';
import 'design_system/themes/zebra_list_item.dart';
import 'domain/services/operacao/operacao_service.dart';
import 'top_navigation_bar.dart';

part 'pdv_page_web_cockpit_section.dart';
part 'pdv_page_web_venda_section.dart';

class PDVWeb extends StatefulWidget {
  const PDVWeb({super.key});

  @override
  State<PDVWeb> createState() => _PDVWebState();
}

enum ModuloCentralPDV {
  seletor,
  cockpit,
  vendas,
  recebimento,
  clientesList,
  colaboradoresList,
  orcamento,
  operacoesCaixa,
  ordemServico,
  agendaFinanceira,
  atendimentoTecnico,
  categorias,
  configuracoes,
}

enum StatusComunicacaoBackend { conectando, conectado, desconectado }

class _PDVWebState extends State<PDVWeb> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _ultimoEventoWebSocket;
  final List<Map<String, dynamic>> _notificacoes = <Map<String, dynamic>>[];
  int _quantidadeNotificacoesNaoLidas = 0;
  StatusComunicacaoBackend _statusComunicacaoBackend =
      StatusComunicacaoBackend.conectando;
  DateTime? _ultimaValidacaoBackend;
  Timer? _monitoramentoComunicacaoTimer;
  DateTime? _ultimaTentativaReconexao;

  late final AnimationController _bellAnimationController;
  late final Animation<double> _bellRotationAnimation;

  final SixThemeResolver _themeResolver = SixThemeResolver();
  late PdvVisualTheme _pdvTheme;

  final OperacaoService _operacaoService = OperacaoModule.operacaoService;

  bool _cockpitAbertoEmDialog = false;
  ModuloCentralPDV _moduloAtual = ModuloCentralPDV.seletor;

  final List<Map<String, dynamic>> _produtosSelecionados =
      <Map<String, dynamic>>[];
  final Set<String> _formasSelecionadas = <String>{};
  bool _registrandoReceberDepois = false;
  ClienteUsuario? _clienteIdentificado;
  int _opcaoCockpitSelecionada = 0;

  final TextEditingController _codigoBarrasController = TextEditingController();
  final TextEditingController _itensTotalController = TextEditingController(
    text: '0',
  );
  final TextEditingController _clienteIdentificadoController =
      TextEditingController();

  final FocusNode _atalhosFocusNode = FocusNode(debugLabel: 'pdv-shortcuts');
  final FocusNode _codigoBarrasFocusNode = FocusNode(
    debugLabel: 'barcode-field',
  );

  final ScrollController _notificacoesScrollController = ScrollController();
  final ScrollController _gradeItensScrollController = ScrollController();
  final ScrollController _resumoVendaScrollController = ScrollController();
  final ScrollController _areaVendaScrollController = ScrollController();

  void _onThemeChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _pdvTheme = PdvVisualThemeResolver.resolve(
        _themeResolver.paleta,
        tema: _themeResolver.tema,
      );
    });
  }

  void _limparFiltrosCockpit() {
    setState(() {
      _opcaoCockpitSelecionada = 0;
    });
  }

  void _selecionarOpcaoCockpit(int index) {
    setState(() {
      _opcaoCockpitSelecionada = index;
    });
  }

  void _voltarParaSeletor() {
    if (_cockpitAbertoEmDialog) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _moduloAtual = ModuloCentralPDV.seletor;
    });
  }

  Future<void> _abrirCockpitEstrategico() async {
    setState(() {
      _opcaoCockpitSelecionada = 0;
      _cockpitAbertoEmDialog = true;
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.of(dialogContext).size;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: size.width * 0.94,
              height: size.height * 0.90,
              child: Column(children: <Widget>[_buildCockpitEstrategico()]),
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _cockpitAbertoEmDialog = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _pdvTheme = PdvVisualThemeResolver.resolve(
      _themeResolver.paleta,
      tema: _themeResolver.tema,
    );
    _themeResolver.addListener(_onThemeChanged);
    _atualizarCamposDerivados();

    _bellAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _bellRotationAnimation = TweenSequence<double>([
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: -0.10),
        weight: 1,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -0.10, end: 0.10),
        weight: 2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.10, end: -0.08),
        weight: 2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -0.08, end: 0.08),
        weight: 2,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.08, end: 0),
        weight: 1,
      ),
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
    onStompConectado = null;
    onStompDesconectado = null;
    onStompErro = null;
    _monitoramentoComunicacaoTimer?.cancel();
    disconnectStomp();
    _bellAnimationController.dispose();
    _atalhosFocusNode.dispose();
    _codigoBarrasFocusNode.dispose();
    _codigoBarrasController.dispose();
    _itensTotalController.dispose();
    _clienteIdentificadoController.dispose();
    _notificacoesScrollController.dispose();
    _gradeItensScrollController.dispose();
    _resumoVendaScrollController.dispose();
    _areaVendaScrollController.dispose();
    super.dispose();
  }

  void _configurarWebSocket() {
    onStompConectado = () {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusComunicacaoBackend = StatusComunicacaoBackend.conectado;
        _ultimaValidacaoBackend = DateTime.now();
      });
    };

    onStompDesconectado = () {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusComunicacaoBackend = StatusComunicacaoBackend.desconectado;
      });
    };

    onStompErro = (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusComunicacaoBackend = StatusComunicacaoBackend.desconectado;
      });
    };

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
        _quantidadeNotificacoesNaoLidas = (_quantidadeNotificacoesNaoLidas + 1)
            .clamp(0, 9);
        _statusComunicacaoBackend = StatusComunicacaoBackend.conectado;
        _ultimaValidacaoBackend = DateTime.now();
      });

      _bellAnimationController.forward(from: 0);

      final String mensagem =
          json['mensagem']?.toString() ?? 'Evento recebido do backend';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
      );
    };

    connectStomp();
    _iniciarMonitoramentoComunicacaoBackend();
  }

  void _iniciarMonitoramentoComunicacaoBackend() {
    _monitoramentoComunicacaoTimer?.cancel();
    _monitoramentoComunicacaoTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _validarComunicacaoBackend(),
    );
  }

  void _validarComunicacaoBackend() {
    if (!mounted) {
      return;
    }

    final bool conectado = isStompConnected();

    if (conectado) {
      if (_statusComunicacaoBackend != StatusComunicacaoBackend.conectado) {
        setState(() {
          _statusComunicacaoBackend = StatusComunicacaoBackend.conectado;
        });
      }
      _ultimaValidacaoBackend = DateTime.now();
      return;
    }

    final DateTime agora = DateTime.now();
    final bool podeReconectar =
        _ultimaTentativaReconexao == null ||
        agora.difference(_ultimaTentativaReconexao!) >=
            const Duration(seconds: 20);

    if (podeReconectar) {
      _ultimaTentativaReconexao = agora;
      setState(() {
        _statusComunicacaoBackend = StatusComunicacaoBackend.conectando;
      });
      connectStomp();
      return;
    }

    if (_statusComunicacaoBackend != StatusComunicacaoBackend.desconectado) {
      setState(() {
        _statusComunicacaoBackend = StatusComunicacaoBackend.desconectado;
      });
    }
  }

  Color _corStatusBackend() {
    switch (_statusComunicacaoBackend) {
      case StatusComunicacaoBackend.conectado:
        return Colors.green.shade500;
      case StatusComunicacaoBackend.conectando:
        return Colors.orange.shade500;
      case StatusComunicacaoBackend.desconectado:
        return Colors.red.shade500;
    }
  }

  String _textoStatusBackend() {
    switch (_statusComunicacaoBackend) {
      case StatusComunicacaoBackend.conectado:
        return 'Backend online';
      case StatusComunicacaoBackend.conectando:
        return 'Validando conexão...';
      case StatusComunicacaoBackend.desconectado:
        return 'Backend offline';
    }
  }

  Widget _buildIndicadorComunicacaoBackend() {
    final Color corStatus = _corStatusBackend();
    final String tooltip =
        _ultimaValidacaoBackend == null
            ? _textoStatusBackend()
            : '${_textoStatusBackend()} • última validação: ${_ultimaValidacaoBackend!.toIso8601String()}';

    return Tooltip(
      message: tooltip,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _pdvTheme.backgroundSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _pdvTheme.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: corStatus,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: corStatus.withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'online',
              style: TextStyle(
                color: _pdvTheme.primaryText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaNotificacoesEConexao() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildIndicadorComunicacaoBackend(),
        const SizedBox(width: 10),
        _buildNotificationBellButton(),
        const SizedBox(width: 10),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Tooltip(
      message: 'Sair da conta',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: _confirmarLogout,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _pdvTheme.backgroundSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _pdvTheme.cardBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.logout_rounded,
                  size: 16,
                  color: _pdvTheme.iconColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Sair',
                  style: TextStyle(
                    color: _pdvTheme.primaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarLogout() async {
    final bool confirmar =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Sair da conta'),
              content: const Text('Deseja encerrar a sessão atual?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Sair'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmar) return;
    await _executarLogout();
  }

  Future<void> _executarLogout() async {
    try {
      await AuthService().logout();
    } catch (e) {
      debugPrint('Falha no logout: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPageWeb()),
      (route) => false,
    );
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
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
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
                    Icon(
                      Icons.notifications_active_rounded,
                      color: theme.colorScheme.primary,
                    ),
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
                  child:
                      _notificacoes.isEmpty
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
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 12),
                            itemBuilder: (BuildContext context, int index) {
                              final Map<String, dynamic> item =
                                  _notificacoes[index];
                              final String ordemId =
                                  item['ordemId']?.toString() ?? '-';
                              final String status =
                                  item['status']?.toString() ?? '-';
                              final String mensagem =
                                  item['mensagem']?.toString() ??
                                  'Sem mensagem';
                              final String recebidoEm =
                                  item['recebidoEm']?.toString() ?? '';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
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
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                          color:
                                              theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
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
                  temNaoLidas
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
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
                      color: _pdvTheme.warningColor.withValues(alpha: 0.35),
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

  Future<void> _abrirSelecaoProdutoWeb({String tipoInicial = 'PRODUTO'}) async {
    final dynamic result = await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.80,
            height: MediaQuery.of(context).size.height * 0.80,
            child: SubPainelWebProdutoLista(
              isSelecao: true,
              permitirSelecaoMultipla: true,
              tipoInicial: tipoInicial,
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    if (result is ProdutoModel) {
      _adicionarProdutoSelecionado(result);
      return;
    }

    if (result is List) {
      final List<ProdutoModel> produtos = result
          .whereType<ProdutoModel>()
          .toList(growable: false);

      if (produtos.isNotEmpty) {
        _adicionarProdutosSelecionados(produtos);
      }
    }
  }

  Future<void> _abrirListaProdutosParaEdicao() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.92,
            height: MediaQuery.of(context).size.height * 0.9,
            child: SubPainelWebProdutoLista(isSelecao: false, modoEdicao: true),
          ),
        );
      },
    );
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
      _clienteIdentificado = null;
      _clienteIdentificadoController.clear();
      _moduloAtual = ModuloCentralPDV.seletor;
    });
  }

  void _adicionarProdutoSelecionado(ProdutoModel produto) {
    setState(() {
      _adicionarProdutoNaListaSemSetState(produto);
      _atualizarCamposDerivados();
    });
  }

  void _adicionarProdutosSelecionados(List<ProdutoModel> produtos) {
    if (produtos.isEmpty) {
      return;
    }

    setState(() {
      for (final ProdutoModel produto in produtos) {
        _adicionarProdutoNaListaSemSetState(produto);
      }

      _atualizarCamposDerivados();
    });
  }

  void _adicionarProdutoNaListaSemSetState(ProdutoModel produto) {
    final String tipoNormalizado = _normalizarTipoProdutoWeb(
      produto.tipoProduto,
    );
    final String chaveProduto = _chaveProdutoVenda(produto);

    final int indexExistente = _produtosSelecionados.indexWhere(
      (Map<String, dynamic> item) => _mesmoProduto(item, produto),
    );

    if (indexExistente >= 0) {
      final int quantidadeAtual =
          (_produtosSelecionados[indexExistente]['quantidade'] ?? 1) as int;
      _produtosSelecionados[indexExistente]['quantidade'] = quantidadeAtual + 1;
      return;
    }

    _produtosSelecionados.add(<String, dynamic>{
      'id': _extrairIdProduto(produto),
      'codigo': produto.codigoDeBarras,
      'nome': produto.nomeProduto,
      'preco': produto.precoVenda,
      'quantidade': 1,
      'tipoProduto': tipoNormalizado,
      'ehServico': _ehServicoTipoWeb(tipoNormalizado),
      'chaveItem': chaveProduto,
      'produtoOriginal': produto,
    });
  }

  bool _mesmoProduto(Map<String, dynamic> item, ProdutoModel produto) {
    final String chaveItem = item['chaveItem']?.toString() ?? '';
    final String chaveProduto = _chaveProdutoVenda(produto);
    if (chaveItem.isNotEmpty) {
      return chaveItem == chaveProduto;
    }

    final String tipoItem = _normalizarTipoProdutoWeb(
      item['tipoProduto']?.toString() ??
          ((item['ehServico'] ?? false) == true ? 'SERVICO' : 'PRODUTO'),
    );
    final String tipoProduto = _normalizarTipoProdutoWeb(produto.tipoProduto);
    if (tipoItem != tipoProduto) return false;

    final dynamic idItem = item['id'];
    final dynamic idProduto = _extrairIdProduto(produto);

    if (idItem != null && idProduto != null) {
      return idItem.toString() == idProduto.toString();
    }

    final String codigoItem = item['codigo']?.toString().trim() ?? '';
    final String codigoProduto = produto.codigoDeBarras.trim();

    if (codigoItem.isNotEmpty && codigoProduto.isNotEmpty) {
      return codigoItem == codigoProduto;
    }

    return item['nome'] == produto.nomeProduto;
  }

  dynamic _extrairIdProduto(ProdutoModel produto) {
    final String? id = produto.id;
    if (id != null && id.trim().isNotEmpty) {
      return id.trim();
    }
    return null;
  }

  String _normalizarTipoProdutoWeb(String tipo) {
    final String normalizado = tipo.trim().toUpperCase();
    if (normalizado == 'SERVICO' || normalizado == 'SERVIÇO') {
      return 'SERVICO';
    }
    return 'PRODUTO';
  }

  bool _ehServicoTipoWeb(String tipo) {
    return _normalizarTipoProdutoWeb(tipo) == 'SERVICO';
  }

  bool _ehServicoItem(Map<String, dynamic> item) {
    final Object? valor = item['ehServico'];
    if (valor == true) return true;
    return _ehServicoTipoWeb(item['tipoProduto']?.toString() ?? '');
  }

  String _chaveProdutoVenda(ProdutoModel produto) {
    final String tipo = _normalizarTipoProdutoWeb(produto.tipoProduto);
    final dynamic id = _extrairIdProduto(produto);
    if (id != null && id.toString().trim().isNotEmpty) {
      return '$tipo:id:${id.toString().trim()}';
    }

    final String codigo = produto.codigoDeBarras.trim();
    if (codigo.isNotEmpty) {
      return '$tipo:codigo:$codigo';
    }

    final String nome = produto.nomeProduto.trim().toLowerCase();
    return '$tipo:nome:$nome|preco:${produto.precoVenda.toStringAsFixed(4)}';
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
    return _produtosSelecionados.fold<double>(0, (
      double soma,
      Map<String, dynamic> item,
    ) {
      return soma +
          (((item['preco'] ?? 0) as num).toDouble() *
              ((item['quantidade'] ?? 1) as int));
    });
  }

  int _calcularQuantidadeItens() {
    return _produtosSelecionados.fold<int>(
      0,
      (int soma, Map<String, dynamic> item) =>
          soma + ((item['quantidade'] ?? 1) as int),
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
    final ClienteIdentificacaoVendaResult? result =
        await showDialog<ClienteIdentificacaoVendaResult>(
          context: context,
          builder: (BuildContext context) {
            return PdvClienteIdentificacaoDialog(
              clienteAtual: _clienteIdentificado,
            );
          },
        );

    if (result == null) {
      return;
    }

    setState(() {
      if (result.limpar) {
        _clienteIdentificado = null;
        _clienteIdentificadoController.clear();
        return;
      }

      final ClienteUsuario? cliente = result.cliente;
      _clienteIdentificado = cliente;
      _clienteIdentificadoController.text =
          cliente?.nome.trim().isNotEmpty == true
              ? cliente!.nome.trim()
              : cliente?.documento.trim() ?? '';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _moduloAtual == ModuloCentralPDV.vendas) {
        _focarCodigoBarras();
      }
    });
  }

  void _abrirOrcamento() {
    setState(() {
      _moduloAtual = ModuloCentralPDV.orcamento;
    });
  }

  void _adicionarServicoRapido() {
    _abrirSelecaoProdutoWeb(tipoInicial: 'SERVICO');
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

    if (event.logicalKey == LogicalKeyboardKey.f8 &&
        _produtosSelecionados.isNotEmpty) {
      _abrirTelaRecebimento();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _confirmarCancelamentoVenda();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _pausarVenda() => _registrarVendaParaReceberDepoisWeb();

  List<ItemVendaAtual> _montarItensDaVendaParaOperacao() {
    return _produtosSelecionados
        .map((Map<String, dynamic> produto) {
          final String idProduto =
              (produto['id'] ?? produto['codigo'] ?? '').toString();

          return ItemVendaAtual(
            idProduto: idProduto,
            nome: (produto['nome'] ?? '').toString(),
            quantidade: (produto['quantidade'] ?? 1) as int,
            valorUnitario: ((produto['preco'] ?? 0) as num).toDouble(),
            ehServico: _ehServicoItem(produto),
          );
        })
        .toList(growable: false);
  }

  Future<void> _registrarVendaParaReceberDepoisWeb() async {
    if (_registrandoReceberDepois) {
      return;
    }

    if (_produtosSelecionados.isEmpty) {
      _mostrarDialogMensagem(
        'Venda vazia',
        'Adicione pelo menos um item antes de registrar para receber depois.',
      );
      return;
    }

    final double total = _calcularTotal();
    final int quantidadeItens = _calcularQuantidadeItens();

    final bool confirmou =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              icon: Icon(
                Icons.schedule_send_outlined,
                color: _pdvTheme.actionButtonBackground,
                size: 34,
              ),
              title: const Text('Receber depois'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'A venda ficará em aberto para liquidação posterior no caixa.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _pdvTheme.iconColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _pdvTheme.cardBorder),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '$quantidadeItens item(ns)',
                              style: TextStyle(
                                color: _pdvTheme.primaryText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            _formatCurrency(total),
                            style: TextStyle(
                              color: _pdvTheme.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Voltar'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Registrar para receber depois'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmou || !mounted) {
      return;
    }

    setState(() => _registrandoReceberDepois = true);

    try {
      final DateTime dataOperacao = DateTime.now();
      final String idColaborador = await AuthService().getUserId() ?? '';

      final OperacaoVendaInput input = OperacaoVendaInput(
        descricao:
            'Venda web para receber depois ${dataOperacao.toIso8601String()}',
        idColaborador: idColaborador,
        nomeColaborador: 'Colaborador',
        itens: _montarItensDaVendaParaOperacao(),
        formasPagamento: const <FormaPagamentoSelecionada>[],
        dataOperacao: dataOperacao,
        receberDepois: true,
      );

      await _operacaoService.finalizarVenda(input);

      if (!mounted) {
        return;
      }

      _limparVendaAposSucessoRecebimento();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Venda registrada para receber depois.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _mostrarDialogMensagem(
        'Erro ao registrar venda',
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _registrandoReceberDepois = false);
      }
    }
  }

  void _abrirTelaRecebimento() {
    if (_produtosSelecionados.isEmpty) {
      _mostrarDialogMensagem(
        'Venda vazia',
        'Adicione pelo menos um item antes de finalizar.',
      );
      return;
    }

    setState(() {
      _moduloAtual = ModuloCentralPDV.recebimento;
    });
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
        'ehServico': _ehServicoItem(produto),
      };
    }).toList();
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2)}';
  }

  String _clienteAtualLabel() {
    final ClienteUsuario? cliente = _clienteIdentificado;
    if (cliente != null) {
      final String nome = cliente.nome.trim();
      if (nome.isNotEmpty) {
        return nome;
      }

      final String documento = cliente.documento.trim();
      if (documento.isNotEmpty) {
        return documento;
      }
    }

    final String nome = _clienteIdentificadoController.text.trim();
    return nome.isEmpty ? 'Não identificado' : nome;
  }

  Widget _buildConteudoCentral(double total) {
    switch (_moduloAtual) {
      case ModuloCentralPDV.cockpit:
        return _buildCockpitEstrategico();

      case ModuloCentralPDV.vendas:
        return _buildAreaVenda(total);

      case ModuloCentralPDV.recebimento:
        return Expanded(
          child: RecebimentoPagamentoWeb(
            embedded: true,
            onBack: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.vendas;
              });

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _focarCodigoBarras();
                }
              });
            },
            onSuccess: _limparVendaAposSucessoRecebimento,
            valorTotalVenda: _calcularTotal(),
            itensResumo: _montarItensResumoPagamento(),
            clienteNome:
                _clienteIdentificado?.nome.trim().isNotEmpty == true
                    ? _clienteIdentificado!.nome.trim()
                    : _clienteIdentificadoController.text.trim(),
            numeroVenda: '',
            idColaborador: 'idUnicoDoColaborador',
            nomeColaborador: 'Nome do colaborador',
            operacaoService: _operacaoService,
          ),
        );

      case ModuloCentralPDV.clientesList:
        return Expanded(
          child: ClientesUsuarioListPage(
            embedded: true,
            onBack: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.seletor;
              });
            },
          ),
        );

      case ModuloCentralPDV.colaboradoresList:
        return Expanded(
          child: ColaboradoresUsuarioListPage(
            embedded: true,
            onBack: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.seletor;
              });
            },
          ),
        );

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
        return Expanded(
          child: OrcamentoWeb(
            embedded: true,
            onBack: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.seletor;
              });
            },
          ),
        );

      case ModuloCentralPDV.ordemServico:
        return Expanded(
          child: OrdemServicoWeb(
            embedded: true,
            onBack: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.seletor;
              });
            },
          ),
        );

      case ModuloCentralPDV.agendaFinanceira:
        return Expanded(
          child: AgendaFinanceiraWeb(
            embedded: true,
            onBack: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.seletor;
              });
            },
          ),
        );

      case ModuloCentralPDV.atendimentoTecnico:
        return Expanded(
          child: AtendimentosTecnicosListaWebPage(
            embedded: true,
            onBack: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.seletor;
              });
            },
          ),
        );

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

      case ModuloCentralPDV.categorias:
        return Expanded(
          child: CategoriasProdutosServicosWebPage(
            embedded: true,
            onBack: () {
              setState(() {
                _moduloAtual = ModuloCentralPDV.seletor;
              });
            },
          ),
        );

      case ModuloCentralPDV.seletor:
        return const Expanded(child: SizedBox.shrink());
    }
  }


  @override
  Widget build(BuildContext context) {
    final double total = _calcularTotal();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _pdvTheme.backgroundPage,
        appBar: TopNavigationBar(
          items: <TopNavItemData>[
            TopNavItemData(
              title: 'Início',
              subItems: const <String>[
                'Meu Perfil',
                'Preferências do Sistema',
                'Painel Administrativo',
              ],
              onSelect: (String value) {
                if (value == 'Meu Perfil') {
                  showMeuPerfilWebDialog(context);
                }

                if (value == 'Painel Administrativo') {
                  showSubPainelConfiguracoes(context, 'Configurações');
                }
              },
            ),
            const TopNavItemData(
              title: 'Permitir',
              subItems: <String>[
                'Gerenciar Permissões',
                'Alterar Configurações',
              ],
            ),
            TopNavItemData(
              title: 'Cadastros',
              subItems: const <String>[
                'Clientes',
                'Clientes List',
                'Produtos',
                'Categorias',
                'Colaboradores',
                'Colaboradores List',
                'Fornecedores',
                'Produtos List',
              ],
              onSelect: (String value) {
                if (value == 'Produtos') {
                  showSubPainelCadastroProduto(context, 'Cadastro de Produtos');
                }

                if (value == 'Clientes') {
                  showSubPainelCadastroCliente(context, 'Cadastro de Clientes');
                }

                if (value == 'Clientes List') {
                  setState(() {
                    _moduloAtual = ModuloCentralPDV.clientesList;
                  });
                }

                if (value == 'Colaboradores') {
                  showSubPainelCadastroColaborador(
                    context,
                    'Cadastro de Colaboradores',
                  );
                }

                if (value == 'Colaboradores List') {
                  setState(() {
                    _moduloAtual = ModuloCentralPDV.colaboradoresList;
                  });
                }

                if (value == 'Produtos List') {
                  _abrirListaProdutosParaEdicao();
                }

                if (value == 'Categorias') {
                  setState(() {
                    _moduloAtual = ModuloCentralPDV.categorias;
                  });
                }
              },
            ),
            TopNavItemData(
              title: 'Configurações',
              subItems: const <String>[
                'formas de recebimentos',
                'exibição aos colaboradores (ex.: habilita so o pdv e esconde o administrativo)',
                'Sistema',
                'Usuários',
                'Preferências do Six',
              ],
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
          notificationWidget: _buildAreaNotificacoesEConexao(),
          onNotificationPressed: _abrirPainelNotificacoes,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 6,
            color: _pdvTheme.backgroundSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: _pdvTheme.cardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: <Widget>[_buildConteudoCentral(total)]),
            ),
          ),
        ),
      ),
    );
  }

  void _limparVendaAposSucessoRecebimento() {
    setState(() {
      _produtosSelecionados.clear();
      _formasSelecionadas.clear();
      _codigoBarrasController.clear();
      _itensTotalController.text = '0';
      _clienteIdentificado = null;
      _clienteIdentificadoController.clear();
      _moduloAtual = ModuloCentralPDV.vendas;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focarCodigoBarras();
      }
    });
  }
}
