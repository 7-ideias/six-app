import 'package:flutter/material.dart';
import '../../../data/models/web_hero_appearance.dart';

/// Shared by the actual header and the administration preview.
LinearGradient sixWebHeroGradient(
  Color surface,
  WebHeroFade fade, {
  required bool compact,
}) {
  return LinearGradient(
    colors: <Color>[
      surface.withValues(alpha: fade.intensity),
      surface.withValues(alpha: 0.95 * fade.intensity),
      surface.withValues(alpha: (compact ? 0.70 : 0.12) * fade.intensity),
    ],
    stops: <double>[0, fade.extent, 1],
  );
}
