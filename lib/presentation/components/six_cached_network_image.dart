import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/services/six_visual_assets_cache.dart';
import 'six_web_cached_image_provider.dart';

class SixCachedNetworkImage extends StatelessWidget {
  const SixCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    this.placeholder,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final Widget? placeholder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image(
        image: SixWebCachedImageProvider(imageUrl),
        gaplessPlayback: false,
        frameBuilder:
            (context, child, frame, synchronous) =>
                synchronous || frame != null ? child : (placeholder ?? child),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        filterQuality: filterQuality,
        errorBuilder: errorBuilder,
        loadingBuilder: loadingBuilder,
      );
    }

    return CachedNetworkImage(
      cacheManager: SixVisualAssetsCache.instance,
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      fadeInDuration: const Duration(milliseconds: 120),
      fadeOutDuration: const Duration(milliseconds: 80),
      placeholder:
          placeholder == null
              ? null
              : (BuildContext context, String _) => placeholder!,
      errorWidget:
          errorBuilder == null
              ? null
              : (BuildContext context, String _, Object error) =>
                  errorBuilder!(context, error, null),
    );
  }
}
