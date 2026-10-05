class WebHeroFade {
  const WebHeroFade({this.intensity = 1, this.extent = 0.42});
  final double intensity;
  final double extent;

  factory WebHeroFade.fromJson(dynamic json) =>
      json is Map
          ? WebHeroFade(
            intensity: _value(json['intensity'], 1),
            extent: _value(json['extent'], 0.42),
          )
          : const WebHeroFade();

  Map<String, double> toJson() => {'intensity': intensity, 'extent': extent};

  static double _value(dynamic value, double fallback) =>
      value is num && value.isFinite ? value.toDouble().clamp(0, 1) : fallback;
}

class WebHeroAppearance {
  const WebHeroAppearance({
    this.light = const WebHeroFade(),
    this.dark = const WebHeroFade(),
  });
  final WebHeroFade light;
  final WebHeroFade dark;

  factory WebHeroAppearance.fromJson(dynamic json) =>
      json is Map
          ? WebHeroAppearance(
            light: WebHeroFade.fromJson(json['light']),
            dark: WebHeroFade.fromJson(json['dark']),
          )
          : const WebHeroAppearance();

  Map<String, dynamic> toJson() => {
    'light': light.toJson(),
    'dark': dark.toJson(),
  };
}
