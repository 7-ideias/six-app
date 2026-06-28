import 'dart:async';
import 'dart:math' as math;

import 'package:sixpos/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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

class TopNavigationBar extends StatefulWidget implements PreferredSizeWidget {
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

  @override
  State<TopNavigationBar> createState() => _TopNavigationBarState();
}

class _TopNavigationBarState extends State<TopNavigationBar> {
  int _keyboardFocusedIndex = 0;
  int? _openMenuIndex;
  final FocusNode _focusNode = FocusNode(debugLabel: 'top-navigation-focus');
  final Map<int, GlobalKey<_TopNavigationMenuItemState>> _itemKeys = {};

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _usaNovoMenuSix {
    final Set<String> titulos = widget.items.map((item) => item.title).toSet();
    return titulos.contains('Cadastros') &&
        titulos.contains('Configurações') &&
        titulos.contains('Início');
  }

  void _ensureItemKeys(int total) {
    _itemKeys.removeWhere((key, _) => key >= total);
    for (var i = 0; i < total; i++) {
      _itemKeys.putIfAbsent(i, () => GlobalKey<_TopNavigationMenuItemState>());
    }

    if (_keyboardFocusedIndex >= total) {
      _keyboardFocusedIndex = math.max(0, total - 1);
    }
  }

  TopNavItemData? _itemOriginal(String title) {
    for (final item in widget.items) {
      if (item.title == title) {
        return item;
      }
    }
    return null;
  }

  void _executarOriginal(String title, String value) {
    final TopNavItemData? item = _itemOriginal(title);
    if (item?.onSelect != null) {
      item!.onSelect!(value);
      return;
    }

    _mostrarRecursoEmPreparacao(value);
  }

  void _mostrarRecursoEmPreparacao(String value) {
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('$value: menu criado. A implementação da tela será evoluída nos próximos passos.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<TopNavItemData> _itemsEfetivos() {
    if (!_usaNovoMenuSix) {
      return widget.items;
    }

    return <TopNavItemData>[
      TopNavItemData(
        title: 'Início',
        subItems: const <String>[],
        onSelect: (_) => _mostrarRecursoEmPreparacao('Início'),
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
        onSelect: (String value) => _mostrarRecursoEmPreparacao(value),
      ),
      TopNavItemData(
        title: 'Catálogo',
        subItems: const <String>['Produtos', 'Serviços', 'Categorias', 'Estoque'],
        onSelect: (String value) {
          if (value == 'Produtos') {
            _executarOriginal('Cadastros', 'Produtos List');
            return;
          }
          _mostrarRecursoEmPreparacao(value);
        },
      ),
      TopNavItemData(
        title: 'Pessoas',
        subItems: const <String>['Clientes', 'Colaboradores', 'Fornecedores'],
        onSelect: (String value) {
          if (value == 'Clientes') {
            _executarOriginal('Cadastros', 'Clientes List');
            return;
          }
          if (value == 'Colaboradores') {
            _executarOriginal('Cadastros', 'Colaboradores List');
            return;
          }
          _executarOriginal('Cadastros', value);
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
        onSelect: (String value) => _mostrarRecursoEmPreparacao(value),
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
        onSelect: (String value) => _mostrarRecursoEmPreparacao(value),
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
        onSelect: (String value) => _mostrarRecursoEmPreparacao('Relatório de $value'),
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
        onSelect: (_) => _executarOriginal('Configurações', 'Preferências do Six'),
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
            _executarOriginal('Início', value);
            return;
          }
          if (value == 'Preferências do Six') {
            _executarOriginal('Configurações', value);
            return;
          }
          _executarOriginal('Cadastros', value);
        },
      ),
    ];
  }

  void _setKeyboardFocus(int index) {
    if (!mounted) return;
    setState(() {
      _keyboardFocusedIndex = index;
    });
  }

  void _requestOpenMenu(int index) {
    for (final entry in _itemKeys.entries) {
      if (entry.key != index) {
        entry.value.currentState?.closeFromExternal();
      }
    }

    if (mounted) {
      setState(() {
        _openMenuIndex = index;
      });
    }
  }

  void _activateTopLevelItem(TopNavItemData item) {
    item.onSelect?.call(item.title);
  }

  void _openMenuFromKeyboard(List<TopNavItemData> items, int index) {
    _setKeyboardFocus(index);
    final TopNavItemData item = items[index];
    if (item.subItems.isEmpty) {
      _activateTopLevelItem(item);
      return;
    }
    _requestOpenMenu(index);
    _itemKeys[index]?.currentState?.openFromExternal();
  }

  void _closeCurrentMenu() {
    final currentIndex = _openMenuIndex;
    if (currentIndex != null) {
      _itemKeys[currentIndex]?.currentState?.closeFromExternal();
    }
    if (mounted) {
      setState(() {
        _openMenuIndex = null;
      });
    }
  }

  KeyEventResult _handleKey(
    List<TopNavItemData> items,
    FocusNode node,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent || items.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowRight) {
      final next = (_keyboardFocusedIndex + 1) % items.length;
      _setKeyboardFocus(next);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      final prev = (_keyboardFocusedIndex - 1 + items.length) % items.length;
      _setKeyboardFocus(prev);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      _openMenuFromKeyboard(items, _keyboardFocusedIndex);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      _closeCurrentMenu();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final List<TopNavItemData> items = _itemsEfetivos();
    _ensureItemKeys(items.length);

    final themeProvider = context.watch<ThemeProvider>();
    final brightness = Theme.of(context).brightness;
    final currentTheme =
        brightness == Brightness.dark
            ? themeProvider.darkTheme
            : themeProvider.lightTheme;
    final colorScheme = currentTheme.colorScheme;

    return Material(
      color: colorScheme.primary,
      child: Focus(
        autofocus: true,
        focusNode: _focusNode,
        onKeyEvent: (node, event) => _handleKey(items, node, event),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1100;

            return AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: compact ? 12 : 24,
              title:
                  compact
                      ? _ResponsiveHeader(
                        items: items,
                        itemKeys: _itemKeys,
                        openMenuIndex: _openMenuIndex,
                        keyboardFocusedIndex: _keyboardFocusedIndex,
                        onKeyboardFocusChanged: _setKeyboardFocus,
                        onMenuOpened: _requestOpenMenu,
                        onMenuClosed: (index) {
                          if (_openMenuIndex == index) {
                            setState(() {
                              _openMenuIndex = null;
                            });
                          }
                        },
                        onTopLevelSelected: _activateTopLevelItem,
                        onNotificationPressed: widget.onNotificationPressed,
                        notificationWidget: widget.notificationWidget,
                      )
                      : Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(items.length, (index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: _TopNavigationMenuItem(
                                      key: _itemKeys[index],
                                      index: index,
                                      data: items[index],
                                      compactMode: false,
                                      isKeyboardFocused:
                                          _keyboardFocusedIndex == index,
                                      shouldBeOpen: _openMenuIndex == index,
                                      onHoverOrFocus:
                                          () => _setKeyboardFocus(index),
                                      onMenuOpened:
                                          () => _requestOpenMenu(index),
                                      onMenuClosed: () {
                                        if (_openMenuIndex == index) {
                                          setState(() {
                                            _openMenuIndex = null;
                                          });
                                        }
                                      },
                                      onTopLevelSelected: _activateTopLevelItem,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          widget.notificationWidget ??
                              IconButton(
                                onPressed: widget.onNotificationPressed,
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
      ),
    );
  }
}

class _ResponsiveHeader extends StatefulWidget {
  final List<TopNavItemData> items;
  final Map<int, GlobalKey<_TopNavigationMenuItemState>> itemKeys;
  final int? openMenuIndex;
  final int keyboardFocusedIndex;
  final ValueChanged<int> onKeyboardFocusChanged;
  final ValueChanged<int> onMenuOpened;
  final ValueChanged<int> onMenuClosed;
  final ValueChanged<TopNavItemData> onTopLevelSelected;
  final VoidCallback? onNotificationPressed;
  final Widget? notificationWidget;

  const _ResponsiveHeader({
    required this.items,
    required this.itemKeys,
    required this.openMenuIndex,
    required this.keyboardFocusedIndex,
    required this.onKeyboardFocusChanged,
    required this.onMenuOpened,
    required this.onMenuClosed,
    required this.onTopLevelSelected,
    required this.onNotificationPressed,
    required this.notificationWidget,
  });

  @override
  State<_ResponsiveHeader> createState() => _ResponsiveHeaderState();
}

class _ResponsiveHeaderState extends State<_ResponsiveHeader> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final brightness = Theme.of(context).brightness;
    final currentTheme =
        brightness == Brightness.dark
            ? themeProvider.darkTheme
            : themeProvider.lightTheme;
    final colorScheme = currentTheme.colorScheme;

    final veryCompact = MediaQuery.of(context).size.width < 760;

    if (!veryCompact) {
      return Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(widget.items.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: _TopNavigationMenuItem(
                      key: widget.itemKeys[index],
                      index: index,
                      data: widget.items[index],
                      compactMode: true,
                      isKeyboardFocused: widget.keyboardFocusedIndex == index,
                      shouldBeOpen: widget.openMenuIndex == index,
                      onHoverOrFocus:
                          () => widget.onKeyboardFocusChanged(index),
                      onMenuOpened: () => widget.onMenuOpened(index),
                      onMenuClosed: () => widget.onMenuClosed(index),
                      onTopLevelSelected: widget.onTopLevelSelected,
                    ),
                  );
                }),
              ),
            ),
          ),
          widget.notificationWidget ??
              IconButton(
                onPressed: widget.onNotificationPressed,
                icon: Icon(
                  Icons.notifications_none,
                  color: colorScheme.onPrimary,
                ),
                tooltip: 'Notificações',
              ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            'Menu',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
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
            onSelected: (selection) {
              final TopNavItemData item = widget.items[selection.menuIndex];
              widget.onKeyboardFocusChanged(selection.menuIndex);
              if (selection.subItem == null) {
                widget.onTopLevelSelected(item);
                return;
              }
              item.onSelect?.call(selection.subItem!);
            },
            itemBuilder: (context) {
              final entries = <PopupMenuEntry<_CompactMenuSelection>>[];
              for (var menuIndex = 0; menuIndex < widget.items.length; menuIndex++) {
                final item = widget.items[menuIndex];
                entries.add(
                  PopupMenuItem<_CompactMenuSelection>(
                    enabled: item.subItems.isEmpty,
                    value: _CompactMenuSelection(menuIndex),
                    child: Text(
                      item.title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );

                for (final subItem in item.subItems) {
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

                if (menuIndex < widget.items.length - 1) {
                  entries.add(const PopupMenuDivider(height: 8));
                }
              }
              return entries;
            },
            icon: Icon(Icons.menu, color: colorScheme.onPrimary),
          ),
        ),
        widget.notificationWidget ??
            IconButton(
              onPressed: widget.onNotificationPressed,
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

class _TopNavigationMenuItem extends StatefulWidget {
  final int index;
  final TopNavItemData data;
  final bool compactMode;
  final bool isKeyboardFocused;
  final bool shouldBeOpen;
  final VoidCallback onHoverOrFocus;
  final VoidCallback onMenuOpened;
  final VoidCallback onMenuClosed;
  final ValueChanged<TopNavItemData> onTopLevelSelected;

  const _TopNavigationMenuItem({
    super.key,
    required this.index,
    required this.data,
    required this.compactMode,
    required this.isKeyboardFocused,
    required this.shouldBeOpen,
    required this.onHoverOrFocus,
    required this.onMenuOpened,
    required this.onMenuClosed,
    required this.onTopLevelSelected,
  });

  @override
  State<_TopNavigationMenuItem> createState() => _TopNavigationMenuItemState();
}

class _TopNavigationMenuItemState extends State<_TopNavigationMenuItem>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _itemFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  Timer? _closeTimer;

  bool _isHoveringTrigger = false;
  bool _isHoveringMenu = false;
  bool _isOpen = false;
  int _highlightedSubIndex = 0;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
      reverseDuration: const Duration(milliseconds: 120),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant _TopNavigationMenuItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shouldBeOpen && !_isOpen) {
      _openMenu();
    } else if (!widget.shouldBeOpen && _isOpen) {
      _closeMenu(immediate: true);
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _overlayEntry?.remove();
    _itemFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void openFromExternal() {
    _openMenu();
  }

  void closeFromExternal() {
    _closeMenu(immediate: true);
  }

  void activateHighlightedOrFirstItem() {
    if (widget.data.subItems.isEmpty) {
      widget.onTopLevelSelected(widget.data);
      return;
    }
    final safeIndex = math.max(
      0,
      math.min(_highlightedSubIndex, widget.data.subItems.length - 1),
    );
    _handleSubItemTap(widget.data.subItems[safeIndex]);
  }

  void _handleSubItemTap(String value) {
    widget.data.onSelect?.call(value);
    _closeMenu();
  }

  void _openMenu() {
    if (widget.data.subItems.isEmpty) {
      widget.onTopLevelSelected(widget.data);
      return;
    }
    if (_isOpen) return;

    widget.onMenuOpened();

    if (_isOpen) return;

    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);

    setState(() {
      _isOpen = true;
      _highlightedSubIndex = 0;
    });

    _animationController.forward(from: 0);
  }

  void _closeMenu({bool immediate = false}) async {
    _closeTimer?.cancel();

    if (!_isOpen) return;

    if (immediate) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) {
        setState(() {
          _isOpen = false;
          _isHoveringMenu = false;
        });
      }
      widget.onMenuClosed();
      return;
    }

    await _animationController.reverse();

    _overlayEntry?.remove();
    _overlayEntry = null;

    if (mounted) {
      setState(() {
        _isOpen = false;
        _isHoveringMenu = false;
      });
    }
    widget.onMenuClosed();
  }

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 180), () {
      if (!_isHoveringTrigger && !_isHoveringMenu) {
        _closeMenu();
      }
    });
  }

  OverlayEntry _buildOverlayEntry() {
    final themeProvider = context.read<ThemeProvider>();
    final brightness = Theme.of(context).brightness;
    final currentTheme =
        brightness == Brightness.dark
            ? themeProvider.darkTheme
            : themeProvider.lightTheme;
    final colorScheme = currentTheme.colorScheme;

    final maxTextLength = widget.data.subItems.fold<int>(
      widget.data.title.length,
      (max, item) => math.max(max, item.length),
    );
    final width = math.min(310.0, math.max(230.0, maxTextLength * 8.5 + 48));

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 48),
            child: MouseRegion(
              onEnter: (_) {
                _closeTimer?.cancel();
                if (mounted) {
                  setState(() {
                    _isHoveringMenu = true;
                  });
                }
              },
              onExit: (_) {
                if (mounted) {
                  setState(() {
                    _isHoveringMenu = false;
                  });
                }
                _scheduleClose();
              },
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    alignment: Alignment.topCenter,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      color: colorScheme.surface,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.1),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 6,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              widget.data.subItems.length,
                              (index) {
                                final item = widget.data.subItems[index];
                                final isHighlighted =
                                    _highlightedSubIndex == index;

                                return _AnimatedSubMenuItem(
                                  label: item,
                                  isHighlighted: isHighlighted,
                                  onHover: () {
                                    if (mounted) {
                                      setState(() {
                                        _highlightedSubIndex = index;
                                      });
                                    }
                                  },
                                  onTap: () => _handleSubItemTap(item),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if ((widget.isKeyboardFocused || _isOpen) &&
        key == LogicalKeyboardKey.arrowDown) {
      if (!_isOpen) {
        _openMenu();
      } else if (mounted && widget.data.subItems.isNotEmpty) {
        setState(() {
          _highlightedSubIndex =
              (_highlightedSubIndex + 1) % widget.data.subItems.length;
        });
      }
      return KeyEventResult.handled;
    }

    if ((widget.isKeyboardFocused || _isOpen) &&
        key == LogicalKeyboardKey.arrowUp) {
      if (_isOpen && widget.data.subItems.isNotEmpty && mounted) {
        setState(() {
          _highlightedSubIndex =
              (_highlightedSubIndex - 1 + widget.data.subItems.length) %
              widget.data.subItems.length;
        });
      }
      return KeyEventResult.handled;
    }

    if ((widget.isKeyboardFocused || _isOpen) &&
        (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space)) {
      if (!_isOpen) {
        _openMenu();
      } else {
        activateHighlightedOrFirstItem();
      }
      return KeyEventResult.handled;
    }

    if (_isOpen && key == LogicalKeyboardKey.escape) {
      _closeMenu();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final brightness = Theme.of(context).brightness;
    final currentTheme =
        brightness == Brightness.dark
            ? themeProvider.darkTheme
            : themeProvider.lightTheme;
    final colorScheme = currentTheme.colorScheme;

    final isActive =
        _isOpen ||
        _isHoveringTrigger ||
        _isHoveringMenu ||
        widget.isKeyboardFocused;

    final horizontalPadding = widget.compactMode ? 10.0 : 12.0;
    final fontSize = widget.compactMode ? 16.0 : 17.0;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        focusNode: _itemFocusNode,
        onKeyEvent: _handleKey,
        child: MouseRegion(
          onEnter: (_) {
            widget.onHoverOrFocus();
            _closeTimer?.cancel();
            if (mounted) {
              setState(() {
                _isHoveringTrigger = true;
              });
            }
            if (widget.data.subItems.isNotEmpty) {
              _openMenu();
            }
          },
          onExit: (_) {
            if (mounted) {
              setState(() {
                _isHoveringTrigger = false;
              });
            }
            _scheduleClose();
          },
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              widget.onHoverOrFocus();
              if (widget.data.subItems.isEmpty) {
                widget.onTopLevelSelected(widget.data);
                return;
              }

              if (_isOpen) {
                _closeMenu();
              } else {
                _openMenu();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color:
                    isActive
                        ? colorScheme.onPrimary.withOpacity(0.12)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  bottom: BorderSide(
                    color:
                        isActive ? colorScheme.onPrimary : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: fontSize,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.data.title),
                    if (widget.data.subItems.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _isOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: colorScheme.onPrimary,
                          size: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSubMenuItem extends StatefulWidget {
  final String label;
  final bool isHighlighted;
  final VoidCallback onHover;
  final VoidCallback onTap;

  const _AnimatedSubMenuItem({
    required this.label,
    required this.isHighlighted,
    required this.onHover,
    required this.onTap,
  });

  @override
  State<_AnimatedSubMenuItem> createState() => _AnimatedSubMenuItemState();
}

class _AnimatedSubMenuItemState extends State<_AnimatedSubMenuItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final brightness = Theme.of(context).brightness;
    final currentTheme =
        brightness == Brightness.dark
            ? themeProvider.darkTheme
            : themeProvider.lightTheme;
    final colorScheme = currentTheme.colorScheme;

    final active = widget.isHighlighted || _hovering;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovering = true;
        });
        widget.onHover();
      },
      onExit: (_) {
        setState(() {
          _hovering = false;
        });
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color:
                active
                    ? colorScheme.primary.withOpacity(0.05)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.transparent),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
