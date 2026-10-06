import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../core/services/web_visual_asset_cache.dart';

/// Flutter's memory cache and the browser's persistent cache share a URL key.
class SixWebCachedImageProvider
    extends ImageProvider<SixWebCachedImageProvider> {
  const SixWebCachedImageProvider(this.url);
  final String url;

  @override
  Future<SixWebCachedImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    SixWebCachedImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1,
      debugLabel: url,
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    try {
      final bytes = await loadWebVisualAsset(url);
      return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (_) {
      // Do not retain failed decodes in either layer; a later load can retry.
      await removeWebVisualAsset(url);
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(this));
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SixWebCachedImageProvider && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
