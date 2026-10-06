import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

const _cacheName = 'six_visual_assets_web_v1';
const _maxEntries = 200;
const _maxBytes = 64 * 1024 * 1024;
const _maxImageBytes = 8 * 1024 * 1024;
const _maxAge = Duration(days: 365);
final _pending = <String, Future<Uint8List>>{};
Future<void> _writes = Future<void>.value();

/// Only public visual assets: no tokens, cookies, or private API responses.
/// The complete URL (including `v`) separates versions and environments.
Future<Uint8List> loadWebVisualAsset(String url) {
  final key = Uri.base.resolve(url).toString();
  return _pending.putIfAbsent(key, () async {
    try {
      return await _load(key);
    } finally {
      _pending.remove(key);
    }
  });
}

Future<web.Cache?> _open() async {
  try {
    return await web.window.caches.open(_cacheName).toDart;
  } catch (_) {
    // Disabled storage, private browsing, and insecure contexts still use HTTP.
    return null;
  }
}

Future<Uint8List> _load(String url) async {
  final cache = await _open();
  if (cache != null) {
    try {
      final hit = await cache.match(url.toJS).toDart;
      if (hit != null) {
        final saved = DateTime.tryParse(
          hit.headers.get('x-six-saved-at') ?? '',
        );
        if (saved != null &&
            DateTime.now().toUtc().difference(saved) < _maxAge) {
          final bytes = (await hit.arrayBuffer().toDart).toDart.asUint8List();
          if (bytes.isNotEmpty) return bytes;
        }
        await cache.delete(url.toJS).toDart;
      }
    } catch (_) {
      // A corrupt/unavailable cache must not prevent the network fallback.
    }
  }

  final controller = web.AbortController();
  final timer = Timer(const Duration(seconds: 20), () => controller.abort());
  late web.Response response;
  late Uint8List bytes;
  try {
    response =
        await web.window
            .fetch(
              url.toJS,
              web.RequestInit(
                credentials: 'omit',
                mode: 'cors',
                signal: controller.signal,
              ),
            )
            .toDart;
    if (!response.ok) throw StateError('Image HTTP ${response.status}');
    bytes = (await response.arrayBuffer().toDart).toDart.asUint8List();
    if (bytes.isEmpty) throw StateError('Empty image');
  } finally {
    timer.cancel();
  }
  final type = response.headers.get('content-type') ?? '';
  if (cache != null &&
      type.startsWith('image/') &&
      bytes.length <= _maxImageBytes) {
    // Serialize writes/eviction within this tab; storage errors never discard
    // an image already fetched successfully.
    final write = _writes.then((_) async {
      try {
        final headers =
            web.Headers()
              ..set('content-type', type)
              ..set('x-six-saved-at', DateTime.now().toUtc().toIso8601String())
              ..set('x-six-byte-length', bytes.length.toString());
        await cache
            .put(
              url.toJS,
              web.Response(bytes.toJS, web.ResponseInit(headers: headers)),
            )
            .toDart;
        await _trim(cache);
      } catch (_) {
        // Includes QuotaExceededError; render from bytes without persistent cache.
      }
    });
    _writes = write;
    await write;
  }
  return bytes;
}

Future<void> _trim(web.Cache cache) async {
  final keys = (await cache.keys().toDart).toDart;
  var total = 0;
  var count = 0;
  // Cache.keys preserves insertion order. Keep the newest entries within budget.
  for (final key in keys.reversed) {
    final entry = await cache.match(key).toDart;
    if (entry == null) continue;
    final size =
        int.tryParse(entry.headers.get('x-six-byte-length') ?? '') ??
        _maxImageBytes;
    final saved = DateTime.tryParse(entry.headers.get('x-six-saved-at') ?? '');
    if (saved == null ||
        DateTime.now().toUtc().difference(saved) >= _maxAge ||
        count >= _maxEntries ||
        total + size > _maxBytes) {
      await cache.delete(key).toDart;
    } else {
      total += size;
      count++;
    }
  }
}

Future<void> removeWebVisualAsset(String url) async {
  try {
    final cache = await _open();
    await cache?.delete(Uri.base.resolve(url).toString().toJS).toDart;
  } catch (_) {}
}
