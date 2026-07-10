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
  Size get preferredSize => const Size.fromHeight(56);

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

  void _abrirLegado(BuildContext context, String title, String value) {
    final item = _itemLegado(title);
    if (item?.onSelect != null) {
      item!.onSelect!(value);
      return;
    }
    _mostrarPreparacao(context, value);
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
        return const _MenuConfigData('Formas de recebimento', 'Métodos aceitos, recebimentos futuros e regras de liquidação.', Icons.payments_rounded);
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
          'Nova venda',
          'Atendimento técnico',
          'Atendimentos criados',
          'Novo orçamento',
          'Nova assistência técnica',
          'Vendas',
          'Orçamentos',
          'Assistências técnicas',
        ],
        onSelect: (value) {
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
        ],
        onSelect: (value) {
          if (value == 'Agenda financeira') return _abrirAgenda(context);
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
          if (value == 'Meu Perfil') return _abrirLegado(context, 'Início', value);
          if (value == 'Preferências do Six') return _abrirLegado(context, 'Configurações', value);
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
    return Material(
      color: colorScheme.primary,
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 18,
        title: Row(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: effectiveItems
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _TopNavigationMenuItem(data: item, colorScheme: colorScheme),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _AppVersionPill(colorScheme: colorScheme),
            const SizedBox(width: 10),
            notificationWidget ??
                IconButton(
                  onPressed: onNotificationPressed,
                  icon: Icon(Icons.notifications_none, color: colorScheme.onPrimary),
                  tooltip: 'Notificações',
                ),
          ],
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
  const _AppVersionPill({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final label = 'v${AppConfig.appVersion}';
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TopNavigationMenuItem extends StatelessWidget {
  const _TopNavigationMenuItem({required this.data, required this.colorScheme});

  final TopNavItemData data;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (data.subItems.isEmpty) {
      return _TopNavChip(
        label: data.title,
        hasMenu: false,
        colorScheme: colorScheme,
        onTap: () => data.onSelect?.call(data.title),
      );
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      onSelected: (value) => data.onSelect?.call(value),
      itemBuilder: (context) => data.subItems
          .map((subItem) => PopupMenuItem<String>(value: subItem, child: Text(subItem)))
          .toList(),
      child: _TopNavChip(label: data.title, hasMenu: true, colorScheme: colorScheme),
    );
  }
}

class _TopNavChip extends StatefulWidget {
  const _TopNavChip({
    required this.label,
    required this.hasMenu,
    required this.colorScheme,
    this.onTap,
  });

  final String label;
  final bool hasMenu;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  @override
  State<_TopNavChip> createState() => _TopNavChipState();
}

class _TopNavChipState extends State<_TopNavChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovering ? widget.colorScheme.onPrimary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.colorScheme.onPrimary,
                  fontSize: 17,
                  fontWeight: _hovering ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
              if (widget.hasMenu)
                Icon(Icons.keyboard_arrow_down_rounded, color: widget.colorScheme.onPrimary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
