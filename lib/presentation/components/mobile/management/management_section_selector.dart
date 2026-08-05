import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';

/// Data for a selectable management section tab.
class ManagementSectionTab {
  const ManagementSectionTab({required this.title, required this.icon});

  final String title;
  final IconData icon;
}

/// Compact horizontal selector for the main management sections.
///
/// Replaces the large parallax carousel with a dense, operational selector
/// suited for daily-use management apps.
class ManagementSectionSelector extends StatefulWidget {
  const ManagementSectionSelector({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onSectionSelected,
  });

  final List<ManagementSectionTab> sections;
  final int selectedIndex;
  final ValueChanged<int> onSectionSelected;

  @override
  State<ManagementSectionSelector> createState() =>
      _ManagementSectionSelectorState();
}

class _ManagementSectionSelectorState extends State<ManagementSectionSelector> {
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _itemKeys = const <GlobalKey>[];
  bool _hintPlayed = false;

  @override
  void initState() {
    super.initState();
    _syncItemKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSelectedVisible();
      _playScrollHint();
    });
  }

  @override
  void didUpdateWidget(covariant ManagementSectionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections.length != widget.sections.length) {
      _syncItemKeys();
    }
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.sections.length != widget.sections.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureSelectedVisible();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _syncItemKeys() {
    _itemKeys = List<GlobalKey>.generate(
      widget.sections.length,
      (int index) => GlobalKey(),
      growable: false,
    );
  }

  void _ensureSelectedVisible() {
    if (!mounted || widget.selectedIndex >= _itemKeys.length) return;
    final BuildContext? selectedContext =
        _itemKeys[widget.selectedIndex].currentContext;
    if (selectedContext == null) return;

    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    Scrollable.ensureVisible(
      selectedContext,
      alignment: 0.5,
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _playScrollHint() async {
    if (_hintPlayed || !mounted) return;
    _hintPlayed = true;

    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reduceMotion || !_scrollController.hasClients) return;

    final double maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0 || widget.selectedIndex != 0) return;

    final double hintOffset = maxScroll < 26 ? maxScroll : 26;
    try {
      await _scrollController.animateTo(
        hintOffset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (!mounted || !_scrollController.hasClients) return;
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final ManagementSectionTab tab = widget.sections[index];
          final bool isSelected = index == widget.selectedIndex;

          return KeyedSubtree(
            key: _itemKeys[index],
            child: _SectionChip(
              key: ValueKey<String>('management-section-tab-$index'),
              tab: tab,
              isSelected: isSelected,
              onTap: () => widget.onSectionSelected(index),
            ),
          );
        },
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
    super.key,
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final ManagementSectionTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: tab.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? SixMobilePalette.primary
                      : SixMobilePalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isSelected
                        ? SixMobilePalette.primary
                        : SixMobilePalette.border,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow:
                  isSelected
                      ? const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  tab.icon,
                  size: 17,
                  color:
                      isSelected
                          ? SixMobilePalette.onPrimary
                          : SixMobilePalette.secondary,
                ),
                const SizedBox(width: 7),
                Text(
                  tab.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isSelected
                            ? SixMobilePalette.onPrimary
                            : SixMobilePalette.titleText,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
