import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_item_data.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_tile.dart';

/// A group card containing a title header and a list of settings tiles.
class ManagementSettingsGroup extends StatelessWidget {
  const ManagementSettingsGroup({super.key, required this.group});

  final ManagementSettingsGroupData group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 9),
          child: Row(
            children: <Widget>[
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: SixMobilePalette.accent.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.75,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: SixMobilePalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: SixMobilePalette.activeBorder,
              width: 0.7,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: SixMobilePalette.navigationShadow,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children:
                group.items.asMap().entries.map((
                  MapEntry<int, ManagementSettingsItemData> entry,
                ) {
                  return ManagementSettingsTile(
                    item: entry.value,
                    isFirst: entry.key == 0,
                    isLast: entry.key == group.items.length - 1,
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
