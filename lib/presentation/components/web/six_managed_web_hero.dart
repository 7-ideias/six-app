import 'package:flutter/material.dart';

import '../../../data/models/web_header_assets_model.dart';
import '../../../data/models/web_hero_appearance.dart';
import 'six_web_hero_gradient.dart';
import '../../../l10n/six_i18n.dart';
import '../../controllers/web_header_assets_context_controller.dart';
import '../../theme/web_theme_tokens.dart';
import '../six_cached_network_image.dart';
import '../six_visual_asset_shimmer.dart';

/// Cabeçalho Web com imagem contextual; o backend resolve escopo e fallback.
class SixManagedWebHero extends StatefulWidget {
  const SixManagedWebHero({
    super.key,
    required this.page,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.icon,
    this.onBack,
    this.actions = const <Widget>[],
  });

  final WebHeaderAssetPage page;
  final String title;
  final String subtitle;
  final String? eyebrow;
  final IconData? icon;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  State<SixManagedWebHero> createState() => _SixManagedWebHeroState();
}

class _SixManagedWebHeroState extends State<SixManagedWebHero> {
  late final WebHeaderAssetsContextController _assets;

  @override
  void initState() {
    super.initState();
    _assets = WebHeaderAssetsContextController()..initialize();
  }

  @override
  void dispose() {
    _assets.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final ThemeData theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _assets,
      builder: (BuildContext context, Widget? _) {
        final WebHeroAppearance appearance =
            _assets.assets?.appearance ?? const WebHeroAppearance();
        final WebHeroFade fade =
            theme.brightness == Brightness.dark
                ? appearance.dark
                : appearance.light;
        final String? resolvedUrl =
            _assets.assets?.asset(widget.page)?.imagemUrl;
        final String? version = _assets.assetsVersion;
        final String? url =
            resolvedUrl == null || version == null
                ? resolvedUrl
                : Uri.parse(resolvedUrl)
                    .replace(
                      queryParameters: <String, String>{
                        ...Uri.parse(resolvedUrl).queryParameters,
                        'v': version,
                      },
                    )
                    .toString();
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compact = constraints.maxWidth < 760;
            final double padding = compact ? 18 : 24;
            return ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                key: ValueKey<String>('web-hero-${widget.page.backendCode}'),
                width: double.infinity,
                constraints: BoxConstraints(minHeight: compact ? 180 : 196),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  border: Border.all(color: tokens.cardBorder),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: IgnorePointer(
                          child:
                              _assets.isLoading
                                  ? const SixVisualAssetShimmer(
                                    borderRadius: 22,
                                  )
                                  : url == null
                                  ? const SizedBox.shrink()
                                  : SixCachedNetworkImage(
                                    // Nova URL/contexto nunca preserva o frame anterior.
                                    key: ValueKey<String>(url),
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.centerRight,
                                    placeholder: const SixVisualAssetShimmer(
                                      borderRadius: 22,
                                    ),
                                    loadingBuilder:
                                        (context, child, progress) =>
                                            progress == null
                                                ? child
                                                : const SixVisualAssetShimmer(
                                                  borderRadius: 22,
                                                ),
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const SizedBox.shrink(),
                                  ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: sixWebHeroGradient(
                              tokens.surface,
                              fade,
                              compact: compact,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(padding),
                      child: SizedBox(
                        width:
                            compact
                                ? double.infinity
                                : (constraints.maxWidth - padding * 2) * 0.75,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (widget.onBack != null) ...<Widget>[
                                  IconButton(
                                    tooltip: context.t(
                                      'common.back',
                                      fallback: 'Voltar',
                                    ),
                                    onPressed: widget.onBack,
                                    icon: const Icon(Icons.arrow_back_rounded),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (widget.icon != null && !compact)
                                  Container(
                                    margin: const EdgeInsets.only(right: 14),
                                    padding: const EdgeInsets.all(13),
                                    decoration: BoxDecoration(
                                      color: tokens.info.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      widget.icon,
                                      color: tokens.info,
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      if (widget.eyebrow != null) ...<Widget>[
                                        Text(
                                          widget.eyebrow!,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: tokens.info,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                      Text(
                                        widget.title,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              color: tokens.primaryText,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        widget.subtitle,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: tokens.secondaryText,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (widget.actions.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: widget.actions,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
