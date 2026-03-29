import 'dart:async';

import 'package:flutter/material.dart';

class TopNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final List<TopNavItemData> items;
  final VoidCallback? onNotificationPressed;

  const TopNavigationBar({
    super.key,
    required this.items,
    this.onNotificationPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue,
      elevation: 0,
      titleSpacing: 24,
      title: Row(
        children: [
          ...items.expand((item) => [
            _TopNavigationMenuItem(data: item),
            const SizedBox(width: 6),
          ]),
          const Spacer(),
          IconButton(
            onPressed: onNotificationPressed,
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.white,
            ),
            tooltip: 'Notificações',
          ),
        ],
      ),
    );
  }
}

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

class _TopNavigationMenuItem extends StatefulWidget {
  final TopNavItemData data;

  const _TopNavigationMenuItem({
    required this.data,
  });

  @override
  State<_TopNavigationMenuItem> createState() => _TopNavigationMenuItemState();
}

class _TopNavigationMenuItemState extends State<_TopNavigationMenuItem> {
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  bool _isHoveringTrigger = false;
  bool _isHoveringMenu = false;
  bool _isOpen = false;
  Timer? _closeTimer;

  void _openMenu() {
    if (_isOpen || widget.data.subItems.isEmpty) return;

    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);

    setState(() {
      _isOpen = true;
    });
  }

  void _closeMenu() {
    _closeTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
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
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 220,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 50),
            child: MouseRegion(
              onEnter: (_) {
                _closeTimer?.cancel();
                setState(() {
                  _isHoveringMenu = true;
                });
              },
              onExit: (_) {
                setState(() {
                  _isHoveringMenu = false;
                });
                _scheduleClose();
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFE6EAF0),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.data.subItems.map((choice) {
                      return _MenuItemTile(
                        label: choice,
                        onTap: () {
                          _closeMenu();
                          widget.data.onSelect?.call(choice);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.data.subItems.isNotEmpty;
    final isActive = _isHoveringTrigger || _isHoveringMenu || _isOpen;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _closeTimer?.cancel();
          setState(() {
            _isHoveringTrigger = true;
          });
          if (hasChildren) {
            _openMenu();
          }
        },
        onExit: (_) {
          setState(() {
            _isHoveringTrigger = false;
          });
          _scheduleClose();
        },
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!hasChildren) return;

            if (_isOpen) {
              _closeMenu();
            } else {
              _openMenu();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border(
                bottom: BorderSide(
                  color: isActive ? Colors.white : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasChildren) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItemTile extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuItemTile({
    required this.label,
    required this.onTap,
  });

  @override
  State<_MenuItemTile> createState() => _MenuItemTileState();
}

class _MenuItemTileState extends State<_MenuItemTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovering = true);
      },
      onExit: (_) {
        setState(() => _hovering = false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _hovering
                ? const Color(0xFFEFF5FF)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF173B67),
            ),
          ),
        ),
      ),
    );
  }
}