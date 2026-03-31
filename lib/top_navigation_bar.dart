import 'dart:async';
import 'dart:math' as math;

import 'package:appplanilha/providers/theme_provider.dart';
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
  void initState() {
    super.initState();
    for (var i = 0; i < widget.items.length; i++) {
      _itemKeys[i] = GlobalKey<_TopNavigationMenuItemState>();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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

  void _openMenuFromKeyboard(int index) {
    _setKeyboardFocus(index);
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

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.items.isEmpty) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowRight) {
      final next = (_keyboardFocusedIndex + 1) % widget.items.length;
      _setKeyboardFocus(next);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      final prev =
          (_keyboardFocusedIndex - 1 + widget.items.length) % widget.items.length;
      _setKeyboardFocus(prev);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      _openMenuFromKeyboard(_keyboardFocusedIndex);
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
    final themeProvider = context.watch<ThemeProvider>();
    final brightness = Theme.of(context).brightness;
    final currentTheme = brightness == Brightness.dark
        ? themeProvider.darkTheme
        : themeProvider.lightTheme;
    final colorScheme = currentTheme.colorScheme;

    return Material(
      color: colorScheme.primary,
      child: Focus(
        autofocus: true,
        focusNode: _focusNode,
        onKeyEvent: _handleKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1100;

            return AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              titleSpacing: compact ? 12 : 24,
              title: compact
                  ? _ResponsiveHeader(
                items: widget.items,
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
                onNotificationPressed: widget.onNotificationPressed,
                notificationWidget: widget.notificationWidget,
              )
                  : Row(
                children: [
                  ...List.generate(widget.items.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: _TopNavigationMenuItem(
                        key: _itemKeys[index],
                        index: index,
                        data: widget.items[index],
                        compactMode: false,
                        isKeyboardFocused: _keyboardFocusedIndex == index,
                        shouldBeOpen: _openMenuIndex == index,
                        onHoverOrFocus: () => _setKeyboardFocus(index),
                        onMenuOpened: () => _requestOpenMenu(index),
                        onMenuClosed: () {
                          if (_openMenuIndex == index) {
                            setState(() {
                              _openMenuIndex = null;
                            });
                          }
                        },
                      ),
                    );
                  }),
                  const Spacer(),
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
    final currentTheme = brightness == Brightness.dark
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
                      onHoverOrFocus: () =>
                          widget.onKeyboardFocusChanged(index),
                      onMenuOpened: () => widget.onMenuOpened(index),
                      onMenuClosed: () => widget.onMenuClosed(index),
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
          child: PopupMenuButton<int>(
            tooltip: 'Abrir menu',
            onSelected: (index) {
              widget.onKeyboardFocusChanged(index);

              final item = widget.items[index];
              if (item.subItems.isNotEmpty) {
                widget.onMenuOpened(index);
                widget.itemKeys[index]?.currentState?.openFromExternal();
              }
            },
            itemBuilder: (context) {
              return List.generate(widget.items.length, (index) {
                return PopupMenuItem<int>(
                  value: index,
                  child: Text(
                    widget.items[index].title,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                );
              });
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

class _TopNavigationMenuItem extends StatefulWidget {
  final int index;
  final TopNavItemData data;
  final bool compactMode;
  final bool isKeyboardFocused;
  final bool shouldBeOpen;
  final VoidCallback onHoverOrFocus;
  final VoidCallback onMenuOpened;
  final VoidCallback onMenuClosed;

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
  String? _selectedSubItem;

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

    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
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
    if (widget.data.subItems.isEmpty) return;
    final safeIndex = math.max(
      0,
      math.min(_highlightedSubIndex, widget.data.subItems.length - 1),
    );
    _handleSubItemTap(widget.data.subItems[safeIndex]);
  }

  void _handleSubItemTap(String value) {
    setState(() {
      _selectedSubItem = value;
    });
    widget.data.onSelect?.call(value);
    _closeMenu();
  }

  void _openMenu() {
    if (_isOpen || widget.data.subItems.isEmpty) return;

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
    final currentTheme = brightness == Brightness.dark
        ? themeProvider.darkTheme
        : themeProvider.lightTheme;
    final colorScheme = currentTheme.colorScheme;

    final width = widget.compactMode ? 210.0 : 230.0;

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
                            color: Theme.of(context)
                                .dividerColor
                                .withOpacity(0.1),
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
                                final isSelected = _selectedSubItem == item;

                                return _AnimatedSubMenuItem(
                                  label: item,
                                  isHighlighted: isHighlighted,
                                  isSelected: isSelected,
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
      } else if (mounted) {
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
        (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.space)) {
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
    final currentTheme = brightness == Brightness.dark
        ? themeProvider.darkTheme
        : themeProvider.lightTheme;
    final colorScheme = currentTheme.colorScheme;

    final isActive =
        _isOpen || _isHoveringTrigger || _isHoveringMenu || widget.isKeyboardFocused;

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
              if (widget.data.subItems.isEmpty) return;

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
                color: isActive
                    ? colorScheme.onPrimary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? colorScheme.onPrimary : Colors.transparent,
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
  final bool isSelected;
  final VoidCallback onHover;
  final VoidCallback onTap;

  const _AnimatedSubMenuItem({
    required this.label,
    required this.isHighlighted,
    required this.isSelected,
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
    final currentTheme = brightness == Brightness.dark
        ? themeProvider.darkTheme
        : themeProvider.lightTheme;
    final colorScheme = currentTheme.colorScheme;

    final active = widget.isSelected || widget.isHighlighted || _hovering;

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
            color: widget.isSelected
                ? colorScheme.primaryContainer
                : active
                ? colorScheme.primary.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isSelected
                  ? colorScheme.primary
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                    widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(
                  Icons.check,
                  size: 16,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}