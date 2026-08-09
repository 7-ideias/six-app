import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';

class OperationalProcedureDemoBadge extends StatelessWidget {
  const OperationalProcedureDemoBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: Container(
        constraints: BoxConstraints(minHeight: 30, maxWidth: 220),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: SixMobilePalette.softNeutralSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: SixMobilePalette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.science_outlined,
              size: 14,
              color: SixMobilePalette.secondary,
            ),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: SixMobilePalette.secondary,
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
