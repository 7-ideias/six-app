import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_item_data.dart';

/// Small badge that communicates the maturity of a settings item.
///
/// Shows nothing for [ManagementSettingsMaturity.functional].
class ManagementSettingsMaturityBadge extends StatelessWidget {
  const ManagementSettingsMaturityBadge({
    super.key,
    required this.maturity,
    required this.label,
  });

  final ManagementSettingsMaturity maturity;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (maturity == ManagementSettingsMaturity.functional) {
      return const SizedBox.shrink();
    }

    final (Color bg, Color fg) = switch (maturity) {
      ManagementSettingsMaturity.experimental => (
        const Color(0xFFFFF7ED),
        const Color(0xFFC2410C),
      ),
      ManagementSettingsMaturity.comingSoon => (
        SixMobilePalette.softNeutralSurface,
        SixMobilePalette.mutedText,
      ),
      ManagementSettingsMaturity.functional => (
        Colors.transparent,
        Colors.transparent,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
