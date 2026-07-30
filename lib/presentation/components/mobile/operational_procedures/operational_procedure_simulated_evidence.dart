import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';

class OperationalProcedureSimulatedEvidence extends StatelessWidget {
  const OperationalProcedureSimulatedEvidence({
    super.key,
    required this.icon,
    required this.label,
    required this.detail,
    required this.onRemove,
    required this.removeLabel,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onRemove;
  final String removeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SixMobilePalette.softAccentSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SixMobilePalette.highlightedBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: SixMobilePalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: SixMobilePalette.border),
            ),
            child: Icon(icon, color: SixMobilePalette.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.titleText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SixMobilePalette.mutedText,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: removeLabel,
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
