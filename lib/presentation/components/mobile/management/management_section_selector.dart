import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
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
        child: SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sections.length,
            separatorBuilder: (_, __) => SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) {
              return _SectionSegment(
                key: ValueKey<String>('management-section-tab-$index'),
                tab: sections[index],
                isSelected: index == selectedIndex,
                onTap: () => onSectionSelected(index),
              );
            },
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
    final SixMobileColorScheme colors = context.sixMobileColors;
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final Color foregroundColor =
        isSelected ? colors.onAccent : colors.titleText;
    final Color segmentColor = isSelected ? colors.accent : colors.surface;
    final Color segmentBorderColor = isSelected ? colors.accent : colors.border;

    return Semantics(
      button: true,
      selected: isSelected,
      label: tab.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: AnimatedContainer(
            duration:
                reduceMotion ? Duration.zero : Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: segmentColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: segmentBorderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(tab.icon, size: 16, color: foregroundColor),
                SizedBox(width: 6),
                Text(
                  tab.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
