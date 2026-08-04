import 'package:flutter/material.dart';

/// Maturity level of a management settings item.
///
/// Controls the visual badge and interaction behavior.
enum ManagementSettingsMaturity {
  /// Fully functional, integrated with backend.
  functional,

  /// Working but uses mocked/local data only.
  experimental,

  /// Not yet implemented in the mobile app.
  comingSoon,
}

/// Data for a single item inside a settings group.
class ManagementSettingsItemData {
  const ManagementSettingsItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.maturity,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ManagementSettingsMaturity maturity;

  /// `null` when the item is disabled / coming soon.
  final VoidCallback? onTap;
}

/// Data for a group of settings items.
class ManagementSettingsGroupData {
  const ManagementSettingsGroupData({required this.title, required this.items});

  final String title;
  final List<ManagementSettingsItemData> items;
}
