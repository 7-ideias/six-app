import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/agenda_financeira_lancamento_service.dart';
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/l10n/app_localizations.dart';
import 'package:sixpos/presentation/components/ai_assistant/ai_assistant_host.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_web.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_lista_web_page.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_web_page.dart';
import 'package:sixpos/presentation/screens/categorias_produtos_servicos_web_page.dart';
import 'package:sixpos/presentation/screens/clientes_usuario_list_page.dart';
import 'package:sixpos/presentation/screens/colaboradores_usuario_list_page.dart';
import 'package:sixpos/presentation/screens/configuracao_secao_web_page.dart';
import 'package:sixpos/presentation/screens/cores_fontes_web_page.dart';
import 'package:sixpos/presentation/screens/desempenho_colaborador_web_page.dart';
import 'package:sixpos/presentation/screens/estoque_dashboard_web_page.dart';
import 'package:sixpos/presentation/screens/fornecedores_web_page.dart';
import 'package:sixpos/presentation/screens/operacoes_caixa_web_page.dart';
import 'package:sixpos/presentation/screens/produto_dashboard_web_page.dart';
import 'package:sixpos/presentation/screens/servico_dashboard_web_page.dart';
import 'package:sixpos/providers/theme_provider.dart';

import 'core/config/app_config.dart';
import 'pdv_page_web.dart';

class TopNavItemData {
  const TopNavItemData({
    required this.title,
    required this.subItems,
    this.onSelect,
  });

  final String title;
  final List<String> subItems;
  final ValueChanged<String>? onSelect;
}

class _MenuConfigData {
  const _MenuConfigData(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

class TopNavigationBar extends StatefulWidget implements PreferredSizeWidget {
  const TopNavigationBar({
    super.key,
    required this.items,
    this.onNotificationPressed,
    this.notificationWidget,
  });

  final List<TopNavItemData> items;
  final VoidCallback? onNotificationPressed;
  final Widget? notificationWidget;

  @override
  Size get preferredSize => const Size.fromHeight(86);

  @override
  State<TopNavigationBar> createState() => _TopNavigationBarState();
}

class _TopNavigationBarState extends State<TopNavigationBar> {
  OverlayEntry? _homeOverlay;
  bool _homeOverlayVisivel = true;
  bool _agendouOverlayInicial = false;
  final ValueNotifier<double> _homeOverlayOpacity = ValueNotifier<double>(1);

  bool get _usaNovoMenuSix {
    final titles = widget.items.map((item) => item.title).toSet();
    return titles.contains('Cadastros') &&
        titles.contains('Configurações') &&
        titles.contains('Início');
  }

  @override
  void didUpdateWidget(covariant TopNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_usaNovoMenuSix) {
      _removerHomeOverlay();
    }
  }

  @override
  void dispose() {
    _removerHomeOverlay();
    _homeOverlayOpacity.dispose();
    super.dispose();
  }

  void _agendarHomeOverlay(BuildContext context) {
    if (!_usaNovoMenuSix || !_homeOverlayVisivel || _agendouOverlayInicial) {
      return;
    }

    _agendouOverlayInicial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_homeOverlayVisivel) return;
      _mostrarHomeOverlay(context);
    });
  }

  void _mostrarHomeOverlay(BuildContext context) {
    if (!_usaNovoMenuSix) return;
    _homeOverlayVisivel = true;
    _homeOverlayOpacity.value = 1;

    if (_homeOverlay != null) {
      _homeOverlay!.markNeedsBuild();
      return;
    }

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _homeOverlay = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          top: widget.preferredSize.height,
          left: 0,
          right: 0,
          bottom: 0,
          child: ValueListenableBuilder<double>(
            valueListenable: _homeOverlayOpacity,
            builder: (context, opacity, child) {
              return IgnorePointer(
                ignoring: opacity < 0.95,
                child: AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: child,
                ),
              );
            },
            child: _SixHomeDashboardOverlay(
              onAbrirPdv: () => _abrirPdvFrenteCaixa(context),
              onAbrirAgenda: () => _abrirAgenda(context),
              onAbrirOperacoesCaixa: () => _abrirOperacoesCaixa(context),
            ),
          ),
        );
      },
    );
    overlay.insert(_homeOverlay!);
  }

  void _ocultarHomeOverlay() {
    _homeOverlayVisivel = false;
    if (_homeOverlay == null) return;
    _homeOverlayOpacity.value = 0;
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted || _homeOverlayVisivel) return;
      _removerHomeOverlay();
    });
  }

  void _removerHomeOverlay() {
    _homeOverlay?.remove();
    _homeOverlay = null;
  }

  TopNavItemData? _itemLegado(String title) {
    for (final item in widget.items) {
      if (item.title == title) return item;
    }
    return null;
  }

  bool _abrirLegado(
    BuildContext context,
    String title,
    String value, {
    bool mostrarPreparacao = true,
  }) {
    final item = _itemLegado(title);
    if (item?.onSelect != null) {
      item!.onSelect!(value);
      return true;
    }
    if (mostrarPreparacao) {
      _mostrarPreparacao(context, value);
    }
    return false;
  }

  void _mostrarPreparacao(BuildContext context, String label) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('$label: menu criado. A tela será evoluída nos próximos passos.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _abrirOverlay(
    BuildContext context,
    Widget Function(BuildContext dialogContext) builder, {
    double widthFactor = 0.94,
    double heightFactor = 0.90,
  }) async {
    _ocultarHomeOverlay();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        return _EscOverlayScope(
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: SizedBox(
              width: size.width * widthFactor,
              height: size.height * heightFactor,
              child: builder(dialogContext),
            ),
          ),
        );
      },
    );
  }

  void _fecharEAbrirLegado(
    BuildContext dialogContext,
    BuildContext context,
    String title,
    String value,
  ) {
    Navigator.of(dialogContext).pop();
    Future<void>.delayed(
      const Duration(milliseconds: 80),
      () => _abrirLegado(context, title, value),
    );
  }

  void _fecharEPreparar(
    BuildContext dialogContext,
    BuildContext context,
    String value,
  ) {
    Navigator.of(dialogContext).pop();
    Future<void>.delayed(
      const Duration(milliseconds: 80),
      () => _mostrarPreparacao(context, value),
    );
  }

  bool _acionarPdvFrenteCaixaNoEstadoAtual(BuildContext context) {
    bool acionado = false;

    context.visitAncestorElements((Element element) {
      if (acionarPdvFrenteCaixaPeloElemento(element)) {
        acionado = true;
        return false;
      }
      return true;
    });

    return acionado;
  }

  void _abrirPdvFrenteCaixa(BuildContext context) {
    _ocultarHomeOverlay();
    if (_acionarPdvFrenteCaixaNoEstadoAtual(context)) {
      return;
    }

    final opened =
        _abrirLegado(context, 'Atendimento', 'PDV - Frente de Caixa', mostrarPreparacao: false) ||
        _abrirLegado(context, 'Executar', 'PDV - Frente de Caixa', mostrarPreparacao: false);

    if (opened) return;

    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      '/app',
      (_) => false,
    );
  }

  void _abrirAtendimentoTecnico(BuildContext context) {
    _abrirOverlay(
      context,
      (dialogContext) => AtendimentosTecnicosWebPage(
        embedded: true,
        onBack: () => Navigator.of(dialogContext).pop(),
      ),
      widthFactor: 0.96,
      heightFactor: 0.92,
    );
  }

  void _abrirAtendimentosCriados(BuildContext context) {
    _abrirOverlay(
      context,
      (dialogContext) => AtendimentosTecnicosListaWebPage(
        embedded: true,
        onBack: () => Navigator.of(dialogContext).pop(),
      ),
      widthFactor: 0.96,
      heightFactor: 0.92,
    );
  }

  void _abrirProdutos(BuildContext context) {
    _abrirOverlay(
      context,
      (dialogContext) => ProdutoDashboardWebPage(
        onBack: () => Navigator.of(dialogContext).pop(),
        onNovoProduto: () => _fecharEAbrirLegado(dialogContext, context, 'Cadastros', 'Produtos'),
        onOpenListaCompleta: () => _fecharEAbrirLegado(dialogContext, context, 'Cadastros', 'Produtos List'),
      ),
    );
  }

  void _abrirServicos(BuildContext context) {
    _abrirOverlay(
      context,
      (dialogContext) => ServicoDashboardWebPage(
        onBack: () => Navigator.of(dialogContext).pop(),
        onNovoServico: () => _fecharEAbrirLegado(dialogContext, context, 'Cadastros', 'Produtos'),
        onOpenListaCompleta: () => _fecharEAbrirLegado(dialogContext, context, 'Cadastros', 'Produtos List'),
      ),
    );
  }

  void _abrirEstoque(BuildContext context) {
    _abrirOverlay(
      context,
      (dialogContext) => EstoqueDashboardWebPage(
        onBack: () => Navigator.of(dialogContext).pop(),
        onEntradaEstoque: () => _fecharEPreparar(dialogContext, context, 'Entrada de estoque'),
        onSaidaEstoque: () => _fecharEPreparar(dialogContext, context, 'Saída de estoque'),
        onAjusteEstoque: () => _fecharEPreparar(dialogContext, context, 'Ajuste de estoque'),
        onOpenListaCompleta: () => _fecharEAbrirLegado(dialogContext, context, 'Cadastros', 'Produtos List'),
      ),
    );
  }

  void _abrirClientes(BuildContext context) {
    _abrirOverlay(
      context,
      (dialogContext) => ClientesUsuarioListPage(
        embedded: true,
        onBack: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  void _abrirCategorias(BuildContext context) {
    _abrirOverlay(
      context,
      (dialogContext) => CategoriasProdutosServicosWebPage(
        embedded: true,
        onBack: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  void _abrirColaboradores(BuildContext context) {
    _abrirOverlay(
      context,
      (dialogContext) => ColaboradoresUsuarioListPage(
        embedded: true,
        onBack: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  void _abrirFornecedores(BuildContext context) {
    _abrirOverlay(
      context,
      (dialogContext) => FornecedoresWebPage(
        embedded: true,
        onBack: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  void _abrirDesempenhoColaborador(BuildContext context) {
    _abrirOverlay(
      context,
      (dialogContext) => DesempenhoColaboradorWebPage(
        onBack: () => Navigator.of(dialogContext).pop(),
      ),
      widthFactor: 0.96,
      heightFactor: 0.92,
    );
  }

  void _abrirAgenda(BuildContext context) {
    _abrirOverlay(
      context,
      (dialogContext) => AgendaFinanceiraWeb(
        embedded: true,
        onBack: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  void _abrirOperacoesCaixa(BuildContext context) {
    _abrirOverlay(
      context,
      (dialogContext) => OperacoesCaixaWebPage(
        embedded: true,
        onBack: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  void _abrirCoresFontes(BuildContext context) {
    _abrirOverlay(
      context,
      (dialogContext) => CoresFontesWebPage(
        embedded: true,
        onBack: () => Navigator.of(dialogContext).pop(),
      ),
      widthFactor: 0.96,
      heightFactor: 0.92,
    );
  }

  void _abrirConfiguracao(BuildContext context, String value) {
    _ocultarHomeOverlay();
    if (value == 'Cores e Fontes') {
      _abrirCoresFontes(context);
      return;
    }

    final data = _config(value);
    _abrirOverlay(
      context,
      (dialogContext) => ConfiguracaoSecaoWebPage(
        title: data.title,
        subtitle: data.subtitle,
        icon: data.icon,
        onBack: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  _MenuConfigData _config(String value) {
    switch (value) {
      case 'Empresa':
        return const _MenuConfigData(
          'Empresa',
          'Dados institucionais, contatos e identidade do comércio.',
          Icons.storefront_rounded,
        );
      case 'Usuários e permissões':
        return const _MenuConfigData(
          'Usuários e permissões',
          'Acessos, perfis de colaboradores e permissões operacionais.',
          Icons.admin_panel_settings_rounded,
        );
      case 'Regionalização':
        return const _MenuConfigData(
          'Regionalização',
          'Idioma, país, moeda, data, hora e formatos locais.',
          Icons.public_rounded,
        );
      case 'Formas de recebimento':
        return const _MenuConfigData(
          'Formas de recebimento',
          'Personalize como sua empresa recebe pagamentos.',
          Icons.payments_rounded,
        );
      case 'Regras operacionais':
        return const _MenuConfigData(
          'Regras operacionais',
          'Estoque, desconto, caixa, comissão e unidades autorizadas para venda.',
          Icons.rule_folder_outlined,
        );
      case 'Notificações':
        return const _MenuConfigData(
          'Notificações',
          'Canais, mensagens e automações para clientes e equipe.',
          Icons.notifications_active_rounded,
        );
      case 'Modelos de PDF':
        return const _MenuConfigData(
          'Modelos de PDF',
          'Modelos de comprovantes, orçamentos e ordens de serviço.',
          Icons.picture_as_pdf_rounded,
        );
      case 'Integrações':
        return const _MenuConfigData(
          'Integrações',
          'Conexões externas para comunicação, pagamentos e automações.',
          Icons.hub_rounded,
        );
      default:
        return _MenuConfigData(value, 'Configuração do Six preparada para evolução.', Icons.tune_rounded);
    }
  }

  List<TopNavItemData> _itemsEfetivos(BuildContext context) {
    if (!_usaNovoMenuSix) return widget.items;
    return <TopNavItemData>[
      TopNavItemData(
        title: 'Início',
        subItems: const <String>[],
        onSelect: (_) {
          _homeOverlayVisivel = true;
          _mostrarHomeOverlay(context);
        },
      ),
      TopNavItemData(
        title: 'Atendimento',
        subItems: const <String>[
          'PDV - Frente de Caixa',
          'Atendimento técnico',
          'Atendimentos criados',
          'Novo orçamento',
          'Nova assistência técnica',
          'Vendas',
          'Orçamentos',
          'Assistências técnicas',
        ],
        onSelect: (value) {
          if (value == 'PDV - Frente de Caixa') {
            _abrirPdvFrenteCaixa(context);
            return;
          }
          if (value == 'Atendimento técnico' || value == 'Nova assistência técnica') {
            _abrirAtendimentoTecnico(context);
            return;
          }
          if (value == 'Atendimentos criados' || value == 'Assistências técnicas') {
            _abrirAtendimentosCriados(context);
            return;
          }
          _ocultarHomeOverlay();
          _mostrarPreparacao(context, value);
        },
      ),
      TopNavItemData(
        title: 'Catálogo',
        subItems: const <String>['Produtos', 'Serviços', 'Categorias', 'Estoque'],
        onSelect: (value) {
          if (value == 'Produtos') {
            _abrirProdutos(context);
            return;
          }
          if (value == 'Serviços') {
            _abrirServicos(context);
            return;
          }
          if (value == 'Categorias') {
            _abrirCategorias(context);
            return;
          }
          if (value == 'Estoque') {
            _abrirEstoque(context);
            return;
          }
          _ocultarHomeOverlay();
          _mostrarPreparacao(context, value);
        },
      ),
      TopNavItemData(
        title: 'Pessoas',
        subItems: const <String>['Clientes', 'Colaboradores', 'Fornecedores', 'Desempenho'],
        onSelect: (value) {
          if (value == 'Clientes') {
            _abrirClientes(context);
            return;
          }
          if (value == 'Colaboradores') {
            _abrirColaboradores(context);
            return;
          }
          if (value == 'Fornecedores') {
            _abrirFornecedores(context);
            return;
          }
          if (value == 'Desempenho') {
            _abrirDesempenhoColaborador(context);
            return;
          }
          _ocultarHomeOverlay();
          _mostrarPreparacao(context, value);
        },
      ),
      TopNavItemData(
        title: 'Caixa',
        subItems: const <String>[
          'Abrir caixa',
          'Fechar caixa',
          'Movimentações',
          'Suprimento',
          'Sangria',
          'Retirada para despesa',
          'Ajustes',
          'Resumo do caixa',
        ],
        onSelect: (value) {
          _ocultarHomeOverlay();
          _mostrarPreparacao(context, value);
        },
      ),
      TopNavItemData(
        title: 'Financeiro',
        subItems: const <String>[
          'Contas a receber',
          'Contas a pagar',
          'Recebimentos futuros',
          'Fiado',
          'Crediário',
          'Agenda financeira',
          'Operações de Caixa',
        ],
        onSelect: (value) {
          if (value == 'Agenda financeira') {
            _abrirAgenda(context);
            return;
          }
          if (value == 'Operações de Caixa') {
            _abrirOperacoesCaixa(context);
            return;
          }
          _ocultarHomeOverlay();
          _mostrarPreparacao(context, value);
        },
      ),
      TopNavItemData(
        title: 'Relatórios',
        subItems: const <String>['Vendas', 'Assistências', 'Caixa', 'Financeiro', 'Produtos', 'Clientes'],
        onSelect: (value) {
          _ocultarHomeOverlay();
          _mostrarPreparacao(context, 'Relatório de $value');
        },
      ),
      TopNavItemData(
        title: 'Configurações',
        subItems: const <String>[
          'Empresa',
          'Cores e Fontes',
          'Usuários e permissões',
          'Regionalização',
          'Formas de recebimento',
          'Regras operacionais',
          'Notificações',
          'Modelos de PDF',
          'Integrações',
        ],
        onSelect: (value) => _abrirConfiguracao(context, value),
      ),
      TopNavItemData(
        title: 'Legado',
        subItems: const <String>[
          'Meu Perfil',
          'Clientes',
          'Clientes List',
          'Produtos',
          'Categorias',
          'Colaboradores',
          'Colaboradores List',
          'Fornecedores',
          'Produtos List',
          'Preferências do Six',
        ],
        onSelect: (value) {
          _ocultarHomeOverlay();
          if (value == 'Meu Perfil') {
            _abrirLegado(context, 'Início', value);
            return;
          }
          if (value == 'Preferências do Six') {
            _abrirLegado(context, 'Configurações', value);
            return;
          }
          _abrirLegado(context, 'Cadastros', value);
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _agendarHomeOverlay(context);
    final themeProvider = context.watch<ThemeProvider>();
    final brightness = Theme.of(context).brightness;
    final currentTheme = brightness == Brightness.dark ? themeProvider.darkTheme : themeProvider.lightTheme;
    final colorScheme = currentTheme.colorScheme;
    final effectiveItems = _itemsEfetivos(context);
    final bool isDark = brightness == Brightness.dark;
    final String aiLabel = AppLocalizations.of(context)?.aiAssistantAsk ?? 'Perguntar à IA';

    return Material(
      color: Colors.transparent,
      child: Container(
        height: widget.preferredSize.height,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const <Color>[Color(0xFF07111E), Color(0xFF0B1B2E)]
                : const <Color>[Color(0xFFF4F7FB), Color(0xFFE7F0FA)],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xE60A1624) : Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.78),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0B1F3A).withOpacity(isDark ? 0.22 : 0.08),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: effectiveItems
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _TopNavigationMenuItem(
                                data: item,
                                colorScheme: colorScheme,
                                premium: true,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _TopbarAiButton(
                  colorScheme: colorScheme,
                  label: aiLabel,
                ),
                const SizedBox(width: 10),
                _AppVersionPill(colorScheme: colorScheme, premium: true),
                const SizedBox(width: 10),
                widget.notificationWidget ??
                    IconButton(
                      onPressed: widget.onNotificationPressed,
                      icon: Icon(Icons.notifications_none, color: colorScheme.primary),
                      tooltip: 'Notificações',
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EscOverlayIntent extends Intent {
  const _EscOverlayIntent();
}

class _EscOverlayScope extends StatelessWidget {
  const _EscOverlayScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _EscOverlayIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _EscOverlayIntent: CallbackAction<_EscOverlayIntent>(
            onInvoke: (_) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}

class _SixHomeDashboardOverlay extends StatefulWidget {
  const _SixHomeDashboardOverlay({
    required this.onAbrirPdv,
    required this.onAbrirAgenda,
    required this.onAbrirOperacoesCaixa,
  });

  final VoidCallback onAbrirPdv;
  final VoidCallback onAbrirAgenda;
  final VoidCallback onAbrirOperacoesCaixa;

  @override
  State<_SixHomeDashboardOverlay> createState() => _SixHomeDashboardOverlayState();
}

class _SixHomeDashboardOverlayState extends State<_SixHomeDashboardOverlay> {
  final AgendaFinanceiraLancamentoService _service = AgendaFinanceiraLancamentoService();

  bool _carregando = true;
  String _usuario = 'usuário';
  String? _erro;
  _HomeSalesSummary _summary = const _HomeSalesSummary.empty();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final usuario = await _resolverUsuario();
      final request = _buildRequestMesAtual();
      final agenda = await _service.consultarLancamentos(request);
      final confirmados = await _service.consultarValoresConfirmados(request);

      if (!mounted) return;
      setState(() {
        _usuario = usuario;
        _summary = _HomeSalesSummary.fromPayloads(agenda: agenda, confirmados: confirmados);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar os dados do período agora.';
      });
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<String> _resolverUsuario() async {
    final email = await AuthService().getUserEmail();
    final base = email?.split('@').first.trim() ?? '';
    if (base.isEmpty) return 'usuário';
    final partes = base
        .split(RegExp(r'[._\-]'))
        .map((parte) => parte.trim())
        .where((parte) => parte.isNotEmpty)
        .toList(growable: false);
    if (partes.isEmpty) return 'usuário';
    final primeiroNome = partes.first;
    return primeiroNome.substring(0, 1).toUpperCase() + primeiroNome.substring(1).toLowerCase();
  }

  AgendaFinanceiraConsultaRequest _buildRequestMesAtual() {
    final hoje = DateTime.now();
    final inicio = DateTime(hoje.year, hoje.month, 1);
    final fim = DateTime(hoje.year, hoje.month + 1, 0);
    return AgendaFinanceiraConsultaRequest(
      periodo: AgendaFinanceiraPeriodoRequest(
        modo: 'ESTE_MES',
        dataInicio: inicio,
        dataFim: fim,
      ),
      filtros: AgendaFinanceiraFiltrosRequest(
        tipo: 'RECEBER',
        status: const <String>[],
        origens: const <String>[],
        categorias: const <String>[],
        formasPagamento: const <String>[],
        clienteFornecedor: null,
        somenteCriticos: false,
      ),
      visaoSelecionada: 'VALORES_CONFIRMADOS',
    );
  }

  String get _saudacao {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  String get _periodoLabel {
    final agora = DateTime.now();
    final mes = agora.month.toString().padLeft(2, '0');
    final ultimoDia = DateTime(agora.year, agora.month + 1, 0).day.toString().padLeft(2, '0');
    return '01/$mes/${agora.year} até $ultimoDia/$mes/${agora.year}';
  }

  String _currency(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const <Color>[Color(0xFF07111E), Color(0xFF0B1B2E), Color(0xFF081422)]
                : const <Color>[Color(0xFFF4F7FB), Color(0xFFE7F0FA), Color(0xFFF8FAFC)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -120,
              top: -180,
              child: _DashboardOrb(size: 360, color: const Color(0xFF2563EB).withOpacity(isDark ? 0.14 : 0.10)),
            ),
            Positioned(
              left: -140,
              bottom: -180,
              child: _DashboardOrb(size: 430, color: const Color(0xFF0B1F3A).withOpacity(isDark ? 0.30 : 0.07)),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _buildHero(isDark),
                        const SizedBox(height: 18),
                        _buildCards(isDark),
                        const SizedBox(height: 18),
                        _buildBottomRow(isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xE60A1624) : Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.78)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0B1F3A).withOpacity(isDark ? 0.22 : 0.08),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF0B1F3A), Color(0xFF2563EB)],
              ),
            ),
            child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$_saudacao, $_usuario',
                  style: TextStyle(
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0B1F3A),
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe o resultado acumulado do período e use o menu superior para acessar os módulos operacionais.',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF8EA6BA) : const Color(0xFF475569),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: _carregando ? null : _carregar,
            icon: _carregando
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
            label: const Text('Atualizar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCards(bool isDark) {
    final venda = _summary.vendasAcumuladas;
    final previsto = _summary.aReceberPrevisto;
    final ticket = _summary.ticketMedio;
    final qtd = _summary.vendasConfirmadas;
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 18,
      crossAxisSpacing: 18,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        _DashboardMetricCard(
          icon: Icons.trending_up_rounded,
          title: 'Vendas acumuladas',
          value: _currency(venda),
          subtitle: 'Recebido confirmado no período',
          isDark: isDark,
          highlight: true,
        ),
        _DashboardMetricCard(
          icon: Icons.pending_actions_rounded,
          title: 'A receber previsto',
          value: _currency(previsto),
          subtitle: 'Saldo aberto dentro do período',
          isDark: isDark,
        ),
        _DashboardMetricCard(
          icon: Icons.receipt_long_rounded,
          title: 'Vendas confirmadas',
          value: '$qtd',
          subtitle: 'Lançamentos recebidos',
          isDark: isDark,
        ),
        _DashboardMetricCard(
          icon: Icons.query_stats_rounded,
          title: 'Ticket médio',
          value: _currency(ticket),
          subtitle: 'Média por venda confirmada',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildBottomRow(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 7,
          child: _DashboardPanel(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.calendar_month_rounded, color: isDark ? Colors.white : const Color(0xFF0B1F3A)),
                    const SizedBox(width: 10),
                    Text(
                      'Período analisado',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0B1F3A),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _periodoLabel,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF8EA6BA) : const Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_erro != null) ...<Widget>[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.25)),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_erro!, style: const TextStyle(fontWeight: FontWeight.w700))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 5,
          child: _DashboardPanel(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Atalhos de operação',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0B1F3A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _DashboardShortcut(label: 'PDV - Frente de Caixa', icon: Icons.point_of_sale_rounded, onPressed: widget.onAbrirPdv),
                    _DashboardShortcut(label: 'Agenda financeira', icon: Icons.monetization_on_rounded, onPressed: widget.onAbrirAgenda),
                    _DashboardShortcut(label: 'Operações de caixa', icon: Icons.account_balance_wallet_rounded, onPressed: widget.onAbrirOperacoesCaixa),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xE60A1624) : Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.78)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0B1F3A).withOpacity(isDark ? 0.18 : 0.07),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HomeSalesSummary {
  const _HomeSalesSummary({
    required this.vendasAcumuladas,
    required this.aReceberPrevisto,
    required this.vendasConfirmadas,
  });

  const _HomeSalesSummary.empty()
      : vendasAcumuladas = 0,
        aReceberPrevisto = 0,
        vendasConfirmadas = 0;

  final double vendasAcumuladas;
  final double aReceberPrevisto;
  final int vendasConfirmadas;

  double get ticketMedio => vendasConfirmadas <= 0 ? 0 : vendasAcumuladas / vendasConfirmadas;

  factory _HomeSalesSummary.fromPayloads({
    required Map<String, dynamic> agenda,
    required Map<String, dynamic> confirmados,
  }) {
    final totais = confirmados['totais'];
    final itensConfirmados = confirmados['itens'];
    final vendasAcumuladas = _toDouble(totais is Map ? totais['totalRecebidoConfirmado'] : null);
    final quantidade = itensConfirmados is List ? itensConfirmados.length : 0;
    double previsto = 0;
    final grupos = agenda['gruposAgenda'];
    if (grupos is List) {
      for (final grupo in grupos) {
        if (grupo is! Map) continue;
        final itens = grupo['itens'];
        if (itens is! List) continue;
        for (final item in itens) {
          if (item is! Map) continue;
          final tipo = item['tipo']?.toString().toUpperCase() ?? '';
          if (tipo == 'PAGAR') continue;
          previsto += _toDouble(item['valorRestante'] ?? item['valorOriginal'] ?? item['valor']);
        }
      }
    }
    return _HomeSalesSummary(
      vendasAcumuladas: vendasAcumuladas,
      aReceberPrevisto: previsto,
      vendasConfirmadas: quantidade,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.isDark,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final bool isDark;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color bg = highlight ? const Color(0xFF0B1F3A) : (isDark ? const Color(0xE60A1624) : Colors.white.withOpacity(0.90));
    final Color primary = highlight ? Colors.white : (isDark ? Colors.white : const Color(0xFF0B1F3A));
    final Color secondary = highlight ? Colors.white.withOpacity(0.72) : (isDark ? const Color(0xFF8EA6BA) : const Color(0xFF64748B));
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: highlight ? const Color(0xFF0B1F3A) : (isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.78))),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0B1F3A).withOpacity(highlight ? 0.18 : (isDark ? 0.20 : 0.08)),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: highlight ? Colors.white.withOpacity(0.14) : const Color(0xFF2563EB).withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: highlight ? Colors.white : const Color(0xFF2563EB)),
          ),
          const Spacer(),
          Text(title, style: TextStyle(color: secondary, fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 6),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: primary, fontWeight: FontWeight.w900, fontSize: 27, letterSpacing: -0.8)),
          const SizedBox(height: 6),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: secondary, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DashboardShortcut extends StatelessWidget {
  const _DashboardShortcut({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DashboardOrb extends StatelessWidget {
  const _DashboardOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _TopbarAiButton extends StatelessWidget {
  const _TopbarAiButton({required this.colorScheme, required this.label});

  final ColorScheme colorScheme;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: AiAssistantWebBridge.toggle,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.auto_awesome_outlined, size: 17, color: colorScheme.primary),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 126),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppVersionPill extends StatelessWidget {
  const _AppVersionPill({required this.colorScheme, this.premium = false});

  final ColorScheme colorScheme;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = premium
        ? (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF8FAFC))
        : colorScheme.onPrimary.withOpacity(0.16);
    final Color border = premium
        ? (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0))
        : colorScheme.onPrimary.withOpacity(0.20);
    final Color text = premium ? colorScheme.primary : colorScheme.onPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        'v${AppConfig.appVersion}',
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class _TopNavigationMenuItem extends StatefulWidget {
  const _TopNavigationMenuItem({required this.data, required this.colorScheme, this.premium = false});

  final TopNavItemData data;
  final ColorScheme colorScheme;
  final bool premium;

  @override
  State<_TopNavigationMenuItem> createState() => _TopNavigationMenuItemState();
}

class _TopNavigationMenuItemState extends State<_TopNavigationMenuItem> {
  bool _open = false;
  bool _hover = false;

  void _showMenu() async {
    setState(() => _open = true);
    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    Timer? autoCloseTimer;
    autoCloseTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !_open) return;
      Navigator.of(context, rootNavigator: true).maybePop();
    });

    final selected = await showMenu<String>(
      context: context,
      useRootNavigator: true,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + box.size.height + 6,
        position.dx + box.size.width,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 18,
      color: Theme.of(context).colorScheme.surface,
      items: widget.data.subItems
          .map(
            (item) => PopupMenuItem<String>(
              value: item,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.arrow_right_rounded, color: widget.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Flexible(child: Text(item, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );

    autoCloseTimer.cancel();
    if (mounted) setState(() => _open = false);
    if (selected != null) {
      widget.data.onSelect?.call(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasChildren = widget.data.subItems.isNotEmpty;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool active = _open || _hover;
    final Color textColor = widget.premium
        ? (active ? widget.colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.76))
        : widget.colorScheme.onPrimary;
    final Color bgColor = widget.premium
        ? (active
            ? (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFF1F5F9))
            : Colors.transparent)
        : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          if (hasChildren) {
            _showMenu();
            return;
          }
          widget.data.onSelect?.call(widget.data.title);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: widget.premium && active
                ? Border.all(color: widget.colorScheme.primary.withOpacity(0.10))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.data.title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              if (hasChildren) ...<Widget>[
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: textColor,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
