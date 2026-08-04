import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_item_data.dart';
import 'package:sixpos/presentation/components/mobile/management/management_settings_maturity_badge.dart';

/// A single settings item tile inside a group card.
///
/// Adjusts opacity, badge and touch behavior based on [ManagementSettingsMaturity].
class ManagementSettingsTile extends StatelessWidget {
  const ManagementSettingsTile({
    super.key,
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  final ManagementSettingsItemData item;
  final bool isFirst;
  final bool isLast;

  bool get _isEnabled => item.maturity != ManagementSettingsMaturity.comingSoon;

  @override
  Widget build(BuildContext context) {
    final double opacity = _isEnabled ? 1.0 : 0.52;
    final String badgeLabel = switch (item.maturity) {
      ManagementSettingsMaturity.experimental => context.t(
        'gestao.settings.badge.experimental',
        fallback: 'Experimental',
      ),
      ManagementSettingsMaturity.comingSoon => context.t(
        'gestao.settings.badge.comingSoon',
        fallback: 'Em breve',
      ),
      ManagementSettingsMaturity.functional => '',
    };

    return Semantics(
      button: _isEnabled,
      enabled: _isEnabled,
      label: item.title,
      hint: item.subtitle,
      child: Opacity(
        opacity: opacity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isFirst ? 20 : 0),
              bottom: Radius.circular(isLast ? 20 : 0),
            ),
            onTap: _isEnabled ? item.onTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                border:
                    isLast
                        ? null
                        : const Border(
                          bottom: BorderSide(
                            color: SixMobilePalette.border,
                            width: 0.5,
                          ),
                        ),
              ),
              child: Row(
                children: <Widget>[
                  _IconBox(icon: item.icon, maturity: item.maturity),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: SixMobilePalette.titleText,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (item.maturity !=
                                ManagementSettingsMaturity.functional) ...[
                              const SizedBox(width: 8),
                              ManagementSettingsMaturityBadge(
                                maturity: item.maturity,
                                label: badgeLabel,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: SixMobilePalette.mutedText,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _isEnabled
                        ? Icons.chevron_right_rounded
                        : Icons.lock_outline_rounded,
                    color: SixMobilePalette.mutedText,
                    size: _isEnabled ? 22 : 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.maturity});

  final IconData icon;
  final ManagementSettingsMaturity maturity;

  @override
  Widget build(BuildContext context) {
    final Color bg =
        maturity == ManagementSettingsMaturity.functional
            ? SixMobilePalette.softAccentSurface
            : SixMobilePalette.softNeutralSurface;
    final Color fg =
        maturity == ManagementSettingsMaturity.functional
            ? SixMobilePalette.accent
            : SixMobilePalette.secondary;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: fg, size: 20),
    );
  }
}
