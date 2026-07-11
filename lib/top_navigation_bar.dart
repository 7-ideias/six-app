import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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

class TopNavigationBar extends StatelessWidget implements PreferredSizeWidget {
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

  bool get _usaNovoMenuSix {
    final titles = items.map((item) => item.title).toSet();
    return titles.contains('Cadastros') &&
        titles.contains('Configurações') &&
        titles.contains('Início');
  }

  TopNavItemData? _itemLegado(String title) {
    for (final item in items) {
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
      if (element is StatefulElement && element.widget.runtimeType.toString() == 'PDVWeb') {
        try {
          final dynamic state = element.state;
          state._iniciarVenda();
          acionado = true;
          return false;
        } catch (_) {
          return true;
        }
      }
      return true;
    });

    return acionado;
  }

  void _abrirPdvFrenteCaixa(BuildContext context) {
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
        return const _MenuConfigData('Empresa', 'Dados institucionais, contatos e identidade do comércio.', Icons.storefront_rounded);
      case 'Usuários e permissões':
        return const _MenuConfigData('Usuários e permissões', 'Acessos, perfis de colaboradores e permissões operacionais.', Icons.admin_panel_settings_rounded);
      case 'Regionalização':
        return const _MenuConfigData('Regionalização', 'Idioma, país, moeda, data, hora e formatos locais.', Icons.public_rounded);
      case 'Formas de recebimento':
        return const _MenuConfigData('Formas de recebimento', 'Personalize como sua empresa recebe pagamentos. Os códigos internos são mantidos pelo sistema, mas o nome e o comportamento podem ser ajustados.', Icons.payments_rounded);
      case 'Regras operacionais':
        return const _MenuConfigData('Regras operacionais', 'Estoque, desconto, caixa, comissão e unidades autorizadas para venda.', Icons.rule_folder_outlined);
      case 'Notificações':
        return const _MenuConfigData('Notificações', 'Canais, mensagens e automações para clientes e equipe.', Icons.notifications_active_rounded);
      case 'Modelos de PDF':
        return const _MenuConfigData('Modelos de PDF', 'Modelos de comprovantes, orçamentos e ordens de serviço.', Icons.picture_as_pdf_rounded);
      case 'Integrações':
        return const _MenuConfigData('Integrações', 'Conexões externas para comunicação, pagamentos e automações.', Icons.hub_rounded);
      default:
        return _MenuConfigData(value, 'Configuração do Six preparada para evolução.', Icons.tune_rounded);
    }
  }

  List<TopNavItemData> _itemsEfetivos(BuildContext context) {
    if (!_usaNovoMenuSix) return items;
    return <TopNavItemData>[
      TopNavItemData(
        title: 'Início',
        subItems: const <String>[],
        onSelect: (_) => Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/app', (_) => false),
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
            return _abrirPdvFrenteCaixa(context);
          }
          if (value == 'Atendimento técnico' || value == 'Nova assistência técnica') {
            return _abrirAtendimentoTecnico(context);
          }
          if (value == 'Atendimentos criados' || value == 'Assistências técnicas') {
            return _abrirAtendimentosCriados(context);
          }
          _mostrarPreparacao(context, value);
        },
      ),
      TopNavItemData(
        title: 'Catálogo',
        subItems: const <String>['Produtos', 'Serviços', 'Categorias', 'Estoque'],
        onSelect: (value) {
          if (value == 'Produtos') return _abrirProdutos(context);
          if (value == 'Serviços') return _abrirServicos(context);
          if (value == 'Categorias') return _abrirCategorias(context);
          if (value == 'Estoque') return _abrirEstoque(context);
          _mostrarPreparacao(context, value);
        },
      ),
      TopNavItemData(
        title: 'Pessoas',
        subItems: const <String>['Clientes', 'Colaboradores', 'Fornecedores', 'Desempenho'],
        onSelect: (value) {
          if (value == 'Clientes') return _abrirClientes(context);
          if (value == 'Colaboradores') return _abrirColaboradores(context);
          if (value == 'Fornecedores') return _abrirFornecedores(context);
          if (value == 'Desempenho') return _abrirDesempenhoColaborador(context);
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
        onSelect: (value) => _mostrarPreparacao(context, value),
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
          if (value == 'Agenda financeira') return _abrirAgenda(context);
          if (value == 'Operações de Caixa') return _abrirOperacoesCaixa(context);
          _mostrarPreparacao(context, value);
        },
      ),
      TopNavItemData(
        title: 'Relatórios',
        subItems: const <String>['Vendas', 'Assistências', 'Caixa', 'Financeiro', 'Produtos', 'Clientes'],
        onSelect: (value) => _mostrarPreparacao(context, 'Relatório de $value'),
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
    final themeProvider = context.watch<ThemeProvider>();
    final brightness = Theme.of(context).brightness;
    final currentTheme = brightness == Brightness.dark ? themeProvider.darkTheme : themeProvider.lightTheme;
    final colorScheme = currentTheme.colorScheme;
    final effectiveItems = _itemsEfetivos(context);
    final bool isDark = brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: preferredSize.height,
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
                              child: _TopNavigationMenuItem(data: item, colorScheme: colorScheme, premium: true),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _AppVersionPill(colorScheme: colorScheme, premium: true),
                const SizedBox(width: 10),
                notificationWidget ??
                    IconButton(
                      onPressed: onNotificationPressed,
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
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + box.size.height + 6,
        position.dx + box.size.width,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 12,
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
