import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';

/// Data for a selectable management section tab.
class ManagementSectionTab {
  ManagementSectionTab({required this.title, required this.icon});

  final String title;
  final IconData icon;
}

/// Compact segmented selector for the main management sections.
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Semantics(
        container: true,
        child: Container(
          key: ValueKey<String>('management-section-selector-surface'),
          height: 52,
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: SixMobilePalette.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: SixMobilePalette.activeBorder, width: 1),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: SixMobilePalette.navigationShadow,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              for (int index = 0; index < sections.length; index += 1)
                Expanded(
                  child: _SectionSegment(
                    key: ValueKey<String>('management-section-tab-$index'),
                    tab: sections[index],
                    isSelected: index == selectedIndex,
                    onTap: () => onSectionSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionSegment extends StatelessWidget {
  const _SectionSegment({
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
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final Color foregroundColor =
        isSelected ? SixMobilePalette.accent : SixMobilePalette.secondary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: tab.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration:
                reduceMotion ? Duration.zero : Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 7),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? SixMobilePalette.accent.withValues(alpha: 0.10)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(tab.icon, size: 17, color: foregroundColor),
                    SizedBox(width: 5),
                    Text(
                      tab.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
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
