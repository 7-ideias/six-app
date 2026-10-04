import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'six_visual_assets_cache.dart';

class VisualAssetManifestCacheService {
  VisualAssetManifestCacheService._();

  static final VisualAssetManifestCacheService instance =
      VisualAssetManifestCacheService._();

  static const String _prefix = 'six_visual_manifest_v1';

  Future<Map<String, dynamic>?> load({
    required String kind,
    required String companyId,
    required String environment,
  }) async {
    if (kIsWeb) return null;

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final String? raw = preferences.getString(
      _key(kind, companyId, environment),
    );
    if (raw == null || raw.isEmpty) return null;

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final Map<String, dynamic> envelope =
          Map<String, dynamic>.from(decoded);
      final dynamic payload = envelope['payload'];
      if (payload is! Map) return null;
      return Map<String, dynamic>.from(payload);
    } catch (error) {
      debugPrint('[VisualAssetsManifest] cache inválido: $error');
      return null;
    }
  }

  Future<bool> prefetchAndSave({
    required String kind,
    required String companyId,
    required String environment,
    required String assetsVersion,
    required Map<String, dynamic> payload,
    required Iterable<String> imageUrls,
  }) async {
    if (kIsWeb) return true;

    final bool prefetched =
        await SixVisualAssetsCache.prefetchAll(imageUrls);
    if (!prefetched) return false;

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final Map<String, dynamic> envelope = <String, dynamic>{
      'environment': environment,
      'assetsVersion': assetsVersion,
      'savedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'payload': payload,
    };
    await preferences.setString(
      _key(kind, companyId, environment),
      jsonEncode(envelope),
    );
    return true;
  }

  Future<void> remove({
    required String kind,
    required String companyId,
  }) async {
    if (kIsWeb) return;
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final String prefix =
        '${_prefix}_${kind.toLowerCase()}_'
        '${Uri.encodeComponent(companyId)}_';
    final List<String> keys = preferences
        .getKeys()
        .where((String key) => key.startsWith(prefix))
        .toList(growable: false);
    for (final String key in keys) {
      await preferences.remove(key);
    }
  }

  Future<void> clearCompany(String companyId) async {
    if (kIsWeb) return;
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();
    final String token = '_${Uri.encodeComponent(companyId)}_';
    final List<String> keys = preferences
        .getKeys()
        .where(
          (String key) =>
              key.startsWith('${_prefix}_') && key.contains(token),
        )
        .toList(growable: false);
    for (final String key in keys) {
      await preferences.remove(key);
    }
  }

  String _key(
    String kind,
    String companyId,
    String environment,
  ) {
    return '${_prefix}_${kind.toLowerCase()}_'
        '${Uri.encodeComponent(companyId)}_'
        '${environment.toUpperCase()}';
  }
}
