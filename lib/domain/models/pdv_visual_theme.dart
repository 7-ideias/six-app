import 'package:flutter/material.dart';

class PdvVisualTheme {
  final Color backgroundPage;
  final Color backgroundSurface;
  final Color backgroundSidebar;
  final Color cardBackground;
  final Color cardBorder;
  final Color cardShadow;
  final Color primaryText;
  final Color secondaryText;
  final Color badgeBackground;
  final Color badgeText;
  final Color iconColor;
  final Color highlightColor;
  final Color successColor;
  final Color warningColor;
  final Color eventCardBackground;
  final Color eventCardBorder;
  final Color actionButtonBackground;
  final Color actionButtonForeground;

  PdvVisualTheme({
    required this.backgroundPage,
    required this.backgroundSurface,
    required this.backgroundSidebar,
    required this.cardBackground,
    required this.cardBorder,
    required this.cardShadow,
    required this.primaryText,
    required this.secondaryText,
    required this.badgeBackground,
    required this.badgeText,
    required this.iconColor,
    required this.highlightColor,
    required this.successColor,
    required this.warningColor,
    required this.eventCardBackground,
    required this.eventCardBorder,
    required this.actionButtonBackground,
    required this.actionButtonForeground,
  });

  factory PdvVisualTheme.defaultTheme() {
    return PdvVisualTheme(
      backgroundPage: const Color(0xFFF4F7FB),
      backgroundSurface: Colors.white,
      backgroundSidebar: const Color(0xFF0B1F3A),
      cardBackground: Colors.white,
      cardBorder: const Color(0xFFE2E8F0),
      cardShadow: const Color(0xFF0B1F3A).withOpacity(0.08),
      primaryText: const Color(0xFF0F172A),
      secondaryText: const Color(0xFF475569),
      badgeBackground: const Color(0xFF2563EB),
      badgeText: Colors.white,
      iconColor: const Color(0xFF1D2B8F),
      highlightColor: const Color(0xFF2563EB),
      successColor: const Color(0xFF16A34A),
      warningColor: const Color(0xFFF59E0B),
      eventCardBackground: const Color(0xFFF8FAFC),
      eventCardBorder: const Color(0xFFE2E8F0),
      actionButtonBackground: const Color(0xFF0B1F3A),
      actionButtonForeground: Colors.white,
    );
  }
}
