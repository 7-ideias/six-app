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
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            group.title.toUpperCase(),
            style: const TextStyle(
              color: SixMobilePalette.mutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: SixMobilePalette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SixMobilePalette.border, width: 0.5),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
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
