import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'web_visual_asset_cache.dart';

class SixVisualAssetsCache {
  SixVisualAssetsCache._();

  static final CacheManager instance = CacheManager(
    Config(
      'six_visual_assets_v1',
      stalePeriod: const Duration(days: 365),
      maxNrOfCacheObjects: 200,
    ),
  );

  static Future<bool> prefetchAll(Iterable<String> urls) async {
    final Set<String> unique =
        urls
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty)
            .toSet();

    if (unique.isEmpty) return true;

    try {
      await Future.wait(
        unique.map(
          (String url) =>
              kIsWeb ? loadWebVisualAsset(url) : instance.getSingleFile(url),
        ),
      );
      return true;
    } catch (error) {
      debugPrint('[VisualAssetsCache] falha no prefetch: $error');
      return false;
    }
  }
}
