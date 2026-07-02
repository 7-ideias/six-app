import 'dart:async';

import 'package:sixpos/presentation/screens/agenda_financeira_web.dart';
import 'package:sixpos/presentation/screens/colaboradores_usuario_list_page.dart';
import 'package:sixpos/presentation/screens/clientes_usuario_list_page.dart';
import 'package:sixpos/presentation/screens/configuracoes_six_web_page.dart';
import 'package:sixpos/presentation/screens/meu_perfil_web_screen.dart';
import 'package:sixpos/presentation/screens/operacoes_caixa_web_page.dart';
import 'package:sixpos/presentation/screens/ordem_servico_web.dart';
import 'package:sixpos/presentation/screens/pdv_cliente_identificacao_dialog.dart';
import 'package:sixpos/presentation/screens/pdv_page_web_orcamento.dart';
import 'package:sixpos/presentation/screens/produto_lista_sub_painel_web.dart';
import 'package:sixpos/presentation/screens/recebimento_pagamento_web.dart';
import 'package:sixpos/providers/telainicial_web_provider.dart';
import 'package:sixpos/sub_painel_cadastro_cliente.dart';
import 'package:sixpos/sub_painel_cadastro_produto.dart';
import 'package:sixpos/sub_painel_configuracoes.dart';
import 'package:sixpos/domain/models/pdv_visual_theme.dart';
import 'package:sixpos/domain/services/aparencia/pdv_visual_theme_resolver.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/l10n/app_localizations.dart';
import 'package:sixpos/sub_painel_cadastro_colaborador.dart';

import 'data/models/cliente_usuario_model.dart';
import 'data/models/produto_model.dart';
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

  int? _cockpitCanalSelecionado;
  int? _cockpitAtendimentoSelecionado;

  late final AnimationController _bellAnimationController;
  late final Animation<double> _bellRotationAnimation;

  final SixThemeResolver _themeResolver = SixThemeResolver();
  late PdvVisualTheme _pdvTheme;

  final OperacaoService _operacaoService = OperacaoModule.operacaoService;

  bool _mostrarDashboardLateral = true;
  ModuloCentralPDV _moduloAtual = ModuloCentralPDV.seletor;

  final List<Map<String, dynamic>> _produtosSelecionados =
      <Map<String, dynamic>>[];
  final Set<String> _formasSelecionadas = <String>{};
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
      _pdvTheme = PdvVisualThemeResolver.resolve(
        _themeResolver.paleta,
        tema: _themeResolver.tema,
      );
    });
  }

  void _limparFiltrosCockpit() {
    setState(() {
      _cockpitCanalSelecionado = null;
      _cockpitAtendimentoSelecionado = null;
    });
  }

  void _selecionarOpcaoCockpit(int index) {
    setState(() {
      _opcaoCockpitSelecionada = index;
    });
  }

  void _voltarParaSeletor() {
    setState(() {
      _moduloAtual = ModuloCentralPDV.seletor;
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
    _sidebarScrollController.dispose();
    _seletorScrollController.dispose();
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
                                                .withOpacity(0.10),
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
      final int indexExistente = _produtosSelecionados.indexWhere(
        (Map<String, dynamic> item) => _mesmoProduto(item, produto),
      );

      if (indexExistente >= 0) {
        _produtosSelecionados[indexExistente]['quantidade'] =
            (_produtosSelecionados[indexExistente]['quantidade'] ?? 1) + 1;
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

    if (codigoItem != null &&
        codigoItem.isNotEmpty &&
        codigoProduto!.isNotEmpty) {
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
        'ehServico': false,
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

  List<Map<String, String>> get _dashboardData => <Map<String, String>>[
    <String, String>{
      'title': 'Vendas Abertas',
      'count':
          TelaInicialWebProvider().telaInicialWeb?.totalVendasAbertas
              .toString() ??
          '0',
    },
    <String, String>{
      'title': 'Ordens Abertas',
      'count':
          TelaInicialWebProvider().telaInicialWeb?.totalOrdensDeServicoAbertas
              .toString() ??
          '0',
    },
    <String, String>{'title': 'OTs em revisão', 'count': '33'},
    <String, String>{'title': 'OTs em processo', 'count': '27'},
    <String, String>{'title': 'OTs finalizadas', 'count': '94'},
    <String, String>{'title': 'OTs atrasadas', 'count': '10'},
  ];

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
    final l10n = AppLocalizations.of(context);

    switch (label) {
      case 'Cockpit':
        badge = 'Gestão visionária';
        descricao =
            'Antecipe riscos de margem, vendas e atendimento com foco em resultado sustentável.';
        break;
      case 'Vendas':
        badge = 'Fluxo principal';
        descricao =
            l10n?.pdvQuickServiceDescription ??
            'Atendimento rápido no caixa, inclusão de itens e fechamento da venda.';
        break;
      case 'Orçamento':
        badge = 'Assistência comercial';
        descricao =
            'Monte propostas com organização, clareza e continuidade do atendimento.';
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
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
                                  : label == 'Cockpit'
                                  ? Icons.visibility_rounded
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
                    child: Icon(icon, size: 34, color: _pdvTheme.iconColor),
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
                Icon(
                  Icons.dashboard_customize_outlined,
                  color: _pdvTheme.iconColor,
                ),
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

    final String ordemId =
        _ultimoEventoWebSocket!['ordemId']?.toString() ?? '-';
    final String status = _ultimoEventoWebSocket!['status']?.toString() ?? '-';
    final String mensagem =
        _ultimoEventoWebSocket!['mensagem']?.toString() ?? 'Sem mensagem';

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
              Icon(
                Icons.notifications_active_rounded,
                color: _pdvTheme.highlightColor,
              ),
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
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _pdvTheme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: $status',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _pdvTheme.primaryText,
            ),
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
                    icon: Icons.space_dashboard_rounded,
                    label: 'Cockpit',
                    onPressed: () {
                      setState(() {
                        _moduloAtual = ModuloCentralPDV.cockpit;
                      });
                    },
                  ),
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
                      setState(() {
                        _moduloAtual = ModuloCentralPDV.ordemServico;
                      });
                    },
                  ),
                  _buildModoOperacaoButton(
                    icon: Icons.monetization_on,
                    label: labelAgendaFinanceira(),
                    onPressed: () {
                      setState(() {
                        _moduloAtual = ModuloCentralPDV.agendaFinanceira;
                      });
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
