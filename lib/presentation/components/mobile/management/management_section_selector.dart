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
class ManagementSectionSelector extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final ManagementSectionTab tab = sections[index];
          final bool isSelected = index == selectedIndex;

          return _SectionChip(
            tab: tab,
            isSelected: isSelected,
            onTap: () => onSectionSelected(index),
          );
        },
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({
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
