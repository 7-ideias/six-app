import 'package:flutter/material.dart';

class ManagementParallaxCardData {
  const ManagementParallaxCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imageAssetPath,
    required this.fallbackGradient,
    this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String imageAssetPath;
  final Gradient fallbackGradient;
  final VoidCallback? onTap;
}
