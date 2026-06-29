import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/presentation/screens/clientes_usuario_list_page.dart';
import 'package:sixpos/presentation/screens/estoque_dashboard_web_page.dart';
import 'package:sixpos/presentation/screens/produto_dashboard_web_page.dart';
import 'package:sixpos/presentation/screens/servico_dashboard_web_page.dart';
import 'package:sixpos/providers/theme_provider.dart';

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
      if (item.title == title) {
        return item;
      }
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

  List<TopNavItemData> _itemsEfetivos(BuildContext context) {
    if (!_usaNovoMenuSix) {
      return items;
    }

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
        onSelect: (String value) => _mostrarRecursoEmPreparacao(context, value),
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
        onSelect: (_) => _executarOriginal(context, 'Configurações', 'Preferências do Six'),
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

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();
    final Brightness brightness = Theme.of(context).brightness;
    final ThemeData currentTheme = brightness == Brightness.dark
        ? themeProvider.darkTheme
        : themeProvider.lightTheme;
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
                      notificationWidget ??
                          IconButton(
                            onPressed: onNotificationPressed,
                            icon: Icon(
                              Icons.notifications_none,
                              color: colorScheme.onPrimary,
                            ),
                            tooltip: 'Notificações',
                          ),
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
              final List<PopupMenuEntry<_CompactMenuSelection>> entries =
                  <PopupMenuEntry<_CompactMenuSelection>>[];

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
                        child: Text(
                          subItem,
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ),
                    ),
                  );
                }

                if (menuIndex < items.length - 1) {
                  entries.add(const PopupMenuDivider(height: 8));
                }
              }

              return entries;
            },
            icon: Icon(Icons.menu_rounded, color: colorScheme.onPrimary),
          ),
        ),
        notificationWidget ??
            IconButton(
              onPressed: onNotificationPressed,
              icon: Icon(
                Icons.notifications_none,
                color: colorScheme.onPrimary,
              ),
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
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 8,
          ),
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
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: widget.colorScheme.onPrimary,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
