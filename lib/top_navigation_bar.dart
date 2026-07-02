import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/presentation/screens/agenda_financeira_web.dart';
import 'package:sixpos/presentation/screens/clientes_usuario_list_page.dart';
import 'package:sixpos/presentation/screens/configuracao_secao_web_page.dart';
import 'package:sixpos/presentation/screens/estoque_dashboard_web_page.dart';
import 'package:sixpos/presentation/screens/produto_dashboard_web_page.dart';
import 'package:sixpos/presentation/screens/servico_dashboard_web_page.dart';
import 'package:sixpos/providers/theme_provider.dart';

import 'core/config/app_config.dart';

class TopNavItemData {
  final String title;
  final List<String> subItems;
  final ValueChanged<String>? onSelect;

  const TopNavItemData({
    required this.title,
    required this.subItems,
    this.onSelect,
  });
}

class _ConfiguracaoMenuData {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ConfiguracaoMenuData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class TopNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final List<TopNavItemData> items;
  final VoidCallback? onNotificationPressed;
  final Widget? notificationWidget;

  const TopNavigationBar({
    super.key,
    required this.items,
    this.onNotificationPressed,
    this.notificationWidget,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  bool get _usaNovoMenuSix {
    final Set<String> titulos = items.map((TopNavItemData item) => item.title).toSet();
    return titulos.contains('Cadastros') &&
        titulos.contains('Configurações') &&
        titulos.contains('Início');
  }

  TopNavItemData? _itemOriginal(String title) {
    for (final TopNavItemData item in items) {
      if (item.title == title) return item;
    }
    return null;
  }

  void _executarOriginal(BuildContext context, String title, String value) {
    final TopNavItemData? item = _itemOriginal(title);
    if (item?.onSelect != null) {
      item!.onSelect!(value);
      return;
    }

    _mostrarRecursoEmPreparacao(context, value);
  }

  void _mostrarRecursoEmPreparacao(BuildContext context, String value) {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('$value: menu criado. A implementação da tela será evoluída nos próximos passos.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _abrirResumoExecutivoProdutos(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.of(dialogContext).size;

        void fecharEExecutar(String title, String value) {
          Navigator.of(dialogContext).pop();
          Future<void>.delayed(const Duration(milliseconds: 80), () {
            _executarOriginal(context, title, value);
          });
        }

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: SizedBox(
            width: size.width * 0.94,
            height: size.height * 0.90,
            child: ProdutoDashboardWebPage(
              onBack: () => Navigator.of(dialogContext).pop(),
              onNovoProduto: () => fecharEExecutar('Cadastros', 'Produtos'),
              onOpenListaCompleta: () => fecharEExecutar('Cadastros', 'Produtos List'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirResumoExecutivoServicos(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.of(dialogContext).size;

        void fecharEExecutar(String title, String value) {
          Navigator.of(dialogContext).pop();
          Future<void>.delayed(const Duration(milliseconds: 80), () {
            _executarOriginal(context, title, value);
          });
        }

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: SizedBox(
            width: size.width * 0.94,
            height: size.height * 0.90,
            child: ServicoDashboardWebPage(
              onBack: () => Navigator.of(dialogContext).pop(),
              onNovoServico: () => fecharEExecutar('Cadastros', 'Produtos'),
              onOpenListaCompleta: () => fecharEExecutar('Cadastros', 'Produtos List'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirResumoOperacionalEstoque(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.of(dialogContext).size;

        void fecharEExecutar(String title, String value) {
          Navigator.of(dialogContext).pop();
          Future<void>.delayed(const Duration(milliseconds: 80), () {
            _executarOriginal(context, title, value);
          });
        }

        void fecharEPreparar(String value) {
          Navigator.of(dialogContext).pop();
          Future<void>.delayed(const Duration(milliseconds: 80), () {
            _mostrarRecursoEmPreparacao(context, value);
          });
        }

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: SizedBox(
            width: size.width * 0.94,
            height: size.height * 0.90,
            child: EstoqueDashboardWebPage(
              onBack: () => Navigator.of(dialogContext).pop(),
              onEntradaEstoque: () => fecharEPreparar('Entrada de estoque'),
              onSaidaEstoque: () => fecharEPreparar('Saída de estoque'),
              onAjusteEstoque: () => fecharEPreparar('Ajuste de estoque'),
              onOpenListaCompleta: () => fecharEExecutar('Cadastros', 'Produtos List'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirGestaoClientes(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.of(dialogContext).size;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: SizedBox(
            width: size.width * 0.94,
            height: size.height * 0.90,
            child: ClientesUsuarioListPage(
              embedded: true,
              onBack: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirAgendaFinanceira(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.of(dialogContext).size;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: SizedBox(
            width: size.width * 0.94,
            height: size.height * 0.90,
            child: AgendaFinanceiraWeb(
              embedded: true,
              onBack: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirConfiguracao(BuildContext context, String value) async {
    final _ConfiguracaoMenuData data = _configuracaoData(value);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final Size size = MediaQuery.of(dialogContext).size;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: SizedBox(
            width: size.width * 0.94,
            height: size.height * 0.90,
            child: ConfiguracaoSecaoWebPage(
              title: data.title,
              subtitle: data.subtitle,
              icon: data.icon,
              onBack: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
  }

  _ConfiguracaoMenuData _configuracaoData(String value) {
    switch (value) {
      case 'Empresa':
        return const _ConfiguracaoMenuData(
          title: 'Empresa',
          subtitle: 'Dados institucionais, contatos e identidade do comércio.',
          icon: Icons.storefront_rounded,
        );
      case 'Usuários e permissões':
        return const _ConfiguracaoMenuData(
          title: 'Usuários e permissões',
          subtitle: 'Acessos, perfis de colaboradores e permissões operacionais.',
          icon: Icons.admin_panel_settings_rounded,
        );
      case 'Regionalização':
        return const _ConfiguracaoMenuData(
          title: 'Regionalização',
          subtitle: 'Idioma, país, moeda, data, hora e formatos locais.',
          icon: Icons.public_rounded,
        );
      case 'Formas de recebimento':
        return const _ConfiguracaoMenuData(
          title: 'Formas de recebimento',
          subtitle: 'Métodos aceitos, recebimentos futuros e regras de liquidação.',
          icon: Icons.payments_rounded,
        );
      case 'Notificações':
        return const _ConfiguracaoMenuData(
          title: 'Notificações',
          subtitle: 'Canais, mensagens e automações para clientes e equipe.',
          icon: Icons.notifications_active_rounded,
        );
      case 'Modelos de PDF':
        return const _ConfiguracaoMenuData(
          title: 'Modelos de PDF',
          subtitle: 'Modelos de comprovantes, orçamentos e ordens de serviço.',
          icon: Icons.picture_as_pdf_rounded,
        );
      case 'Integrações':
        return const _ConfiguracaoMenuData(
          title: 'Integrações',
          subtitle: 'Conexões externas para comunicação, pagamentos e automações.',
          icon: Icons.hub_rounded,
        );
      default:
        return _ConfiguracaoMenuData(
          title: value,
          subtitle: 'Configuração do Six preparada para evolução.',
          icon: Icons.tune_rounded,
        );
    }
  }

  List<TopNavItemData> _itemsEfetivos(BuildContext context) {
    if (!_usaNovoMenuSix) return items;

    return <TopNavItemData>[
      TopNavItemData(
        title: 'Início',
        subItems: const <String>[],
        onSelect: (_) => _mostrarRecursoEmPreparacao(context, 'Início'),
      ),
      TopNavItemData(
        title: 'Atendimento',
        subItems: const <String>[
          'Nova venda',
          'Novo orçamento',
          'Nova assistência técnica',
          'Vendas',
          'Orçamentos',
          'Assistências técnicas',
        ],
        onSelect: (String value) => _mostrarRecursoEmPreparacao(context, value),
      ),
      TopNavItemData(
        title: 'Catálogo',
        subItems: const <String>['Produtos', 'Serviços', 'Categorias', 'Estoque'],
        onSelect: (String value) {
          if (value == 'Produtos') {
            _abrirResumoExecutivoProdutos(context);
            return;
          }
          if (value == 'Serviços') {
            _abrirResumoExecutivoServicos(context);
            return;
          }
          if (value == 'Estoque') {
            _abrirResumoOperacionalEstoque(context);
            return;
          }
          _mostrarRecursoEmPreparacao(context, value);
        },
      ),
      TopNavItemData(
        title: 'Pessoas',
        subItems: const <String>['Clientes', 'Colaboradores', 'Fornecedores'],
        onSelect: (String value) {
          if (value == 'Clientes') {
            _abrirGestaoClientes(context);
            return;
          }
          if (value == 'Colaboradores') {
            _executarOriginal(context, 'Cadastros', 'Colaboradores List');
            return;
          }
          _executarOriginal(context, 'Cadastros', value);
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
        onSelect: (String value) => _mostrarRecursoEmPreparacao(context, value),
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
        onSelect: (String value) {
          if (value == 'Agenda financeira') {
            _abrirAgendaFinanceira(context);
            return;
          }
          _mostrarRecursoEmPreparacao(context, value);
        },
      ),
      TopNavItemData(
        title: 'Relatórios',
        subItems: const <String>[
          'Vendas',
          'Assistências',
          'Caixa',
          'Financeiro',
          'Produtos',
          'Clientes',
        ],
        onSelect: (String value) => _mostrarRecursoEmPreparacao(context, 'Relatório de $value'),
      ),
      TopNavItemData(
        title: 'Configurações',
        subItems: const <String>[
          'Empresa',
          'Usuários e permissões',
          'Regionalização',
          'Formas de recebimento',
          'Notificações',
          'Modelos de PDF',
          'Integrações',
        ],
        onSelect: (String value) => _abrirConfiguracao(context, value),
      ),
      TopNavItemData(
        title: 'Legado',
        subItems: const <String>[
          'Meu Perfil',
          'Clientes',
          'Clientes List',
          'Produtos',
          'Colaboradores',
          'Colaboradores List',
          'Fornecedores',
          'Produtos List',
          'Preferências do Six',
        ],
        onSelect: (String value) {
          if (value == 'Meu Perfil') {
            _executarOriginal(context, 'Início', value);
            return;
          }
          if (value == 'Preferências do Six') {
            _executarOriginal(context, 'Configurações', value);
            return;
          }
          _executarOriginal(context, 'Cadastros', value);
        },
      ),
    ];
  }

  Widget _buildTrailingArea(ColorScheme colorScheme) {
    final Widget notifications = notificationWidget ??
        IconButton(
          onPressed: onNotificationPressed,
          icon: Icon(Icons.notifications_none, color: colorScheme.onPrimary),
          tooltip: 'Notificações',
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _AppVersionPill(colorScheme: colorScheme),
        const SizedBox(width: 10),
        notifications,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();
    final Brightness brightness = Theme.of(context).brightness;
    final ThemeData currentTheme = brightness == Brightness.dark ? themeProvider.darkTheme : themeProvider.lightTheme;
    final ColorScheme colorScheme = currentTheme.colorScheme;
    final List<TopNavItemData> effectiveItems = _itemsEfetivos(context);

    return Material(
      color: colorScheme.primary,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool veryCompact = constraints.maxWidth < 760;
          final bool compact = constraints.maxWidth < 1100;

          return AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: compact ? 12 : 24,
            title: veryCompact
                ? _CompactHeader(
                    items: effectiveItems,
                    colorScheme: colorScheme,
                    onNotificationPressed: onNotificationPressed,
                    notificationWidget: notificationWidget,
                  )
                : Row(
                    children: <Widget>[
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: effectiveItems.map((TopNavItemData item) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _TopNavigationMenuItem(
                                  data: item,
                                  colorScheme: colorScheme,
                                  compactMode: compact,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildTrailingArea(colorScheme),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  final List<TopNavItemData> items;
  final ColorScheme colorScheme;
  final VoidCallback? onNotificationPressed;
  final Widget? notificationWidget;

  const _CompactHeader({
    required this.items,
    required this.colorScheme,
    required this.onNotificationPressed,
    required this.notificationWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Menu',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              color: colorScheme.surface,
              textStyle: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          child: PopupMenuButton<_CompactMenuSelection>(
            tooltip: 'Abrir menu',
            onSelected: (_CompactMenuSelection selection) {
              final TopNavItemData item = items[selection.menuIndex];
              if (selection.subItem == null) {
                item.onSelect?.call(item.title);
                return;
              }
              item.onSelect?.call(selection.subItem!);
            },
            itemBuilder: (BuildContext context) {
              final List<PopupMenuEntry<_CompactMenuSelection>> entries = <PopupMenuEntry<_CompactMenuSelection>>[];

              for (int menuIndex = 0; menuIndex < items.length; menuIndex++) {
                final TopNavItemData item = items[menuIndex];
                entries.add(
                  PopupMenuItem<_CompactMenuSelection>(
                    enabled: item.subItems.isEmpty,
                    value: _CompactMenuSelection(menuIndex),
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );

                for (final String subItem in item.subItems) {
                  entries.add(
                    PopupMenuItem<_CompactMenuSelection>(
                      value: _CompactMenuSelection(menuIndex, subItem),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(subItem, style: TextStyle(color: colorScheme.onSurface)),
                      ),
                    ),
                  );
                }

                if (menuIndex < items.length - 1) entries.add(const PopupMenuDivider(height: 8));
              }

              return entries;
            },
            icon: Icon(Icons.menu_rounded, color: colorScheme.onPrimary),
          ),
        ),
        const SizedBox(width: 8),
        _AppVersionPill(colorScheme: colorScheme, compact: true),
        const SizedBox(width: 8),
        notificationWidget ??
            IconButton(
              onPressed: onNotificationPressed,
              icon: Icon(Icons.notifications_none, color: colorScheme.onPrimary),
              tooltip: 'Notificações',
            ),
      ],
    );
  }
}

class _CompactMenuSelection {
  final int menuIndex;
  final String? subItem;

  const _CompactMenuSelection(this.menuIndex, [this.subItem]);
}

class _AppVersionPill extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool compact;

  const _AppVersionPill({
    required this.colorScheme,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final String label = 'v${AppConfig.appVersion}';

    return Tooltip(
      message: 'Versão atual: ${AppConfig.appVersion}',
      child: Container(
        height: compact ? 34 : 36,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colorScheme.onPrimary.withOpacity(0.18)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

class _TopNavigationMenuItem extends StatelessWidget {
  final TopNavItemData data;
  final ColorScheme colorScheme;
  final bool compactMode;

  const _TopNavigationMenuItem({
    required this.data,
    required this.colorScheme,
    required this.compactMode,
  });

  @override
  Widget build(BuildContext context) {
    if (data.subItems.isEmpty) {
      return _TopNavChip(
        label: data.title,
        hasMenu: false,
        compactMode: compactMode,
        colorScheme: colorScheme,
        onTap: () => data.onSelect?.call(data.title),
      );
    }

    return PopupMenuButton<String>(
      tooltip: data.title,
      offset: const Offset(0, 44),
      onSelected: (String value) => data.onSelect?.call(value),
      itemBuilder: (BuildContext context) {
        return data.subItems.map((String subItem) {
          return PopupMenuItem<String>(
            value: subItem,
            child: Text(subItem),
          );
        }).toList();
      },
      child: _TopNavChip(
        label: data.title,
        hasMenu: true,
        compactMode: compactMode,
        colorScheme: colorScheme,
      ),
    );
  }
}

class _TopNavChip extends StatefulWidget {
  final String label;
  final bool hasMenu;
  final bool compactMode;
  final ColorScheme colorScheme;
  final VoidCallback? onTap;

  const _TopNavChip({
    required this.label,
    required this.hasMenu,
    required this.compactMode,
    required this.colorScheme,
    this.onTap,
  });

  @override
  State<_TopNavChip> createState() => _TopNavChipState();
}

class _TopNavChipState extends State<_TopNavChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _hovering;
    final double horizontalPadding = widget.compactMode ? 10 : 12;
    final double fontSize = widget.compactMode ? 16 : 17;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          decoration: BoxDecoration(
            color: active ? widget.colorScheme.onPrimary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              bottom: BorderSide(
                color: active ? widget.colorScheme.onPrimary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.colorScheme.onPrimary,
                  fontSize: fontSize,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
              if (widget.hasMenu) ...<Widget>[
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, color: widget.colorScheme.onPrimary, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
