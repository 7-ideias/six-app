import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sixpos/data/models/produto_imagem_model.dart';

class ProdutoWebImage extends StatelessWidget {
  const ProdutoWebImage({
    super.key,
    required this.image,
    required this.fallback,
    this.previewBytes,
    this.preferThumbnail = false,
    this.fit = BoxFit.cover,
    this.loadingSize = 22,
  });

  final ProdutoImagemModel? image;
  final Uint8List? previewBytes;
  final bool preferThumbnail;
  final BoxFit fit;
  final double loadingSize;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final ProdutoWebImageSource source = ProdutoWebImageResolver.resolve(
      image,
      previewBytes: previewBytes,
      preferThumbnail: preferThumbnail,
    );

    if (!source.hasImage) {
      return fallback;
    }

    Widget loadingBuilder(
      BuildContext context,
      Widget child,
      ImageChunkEvent? loadingProgress,
    ) {
      if (loadingProgress == null) return child;
      return Center(
        child: SizedBox(
          width: loadingSize,
          height: loadingSize,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (source.dataUrl != null) {
      return Image.network(
        source.dataUrl!,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: loadingBuilder,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Image.network(
      source.url!,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: loadingBuilder,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class ProdutoWebImageSource {
  const ProdutoWebImageSource._({this.dataUrl, this.url});

  factory ProdutoWebImageSource.dataUrl(String value) =>
      ProdutoWebImageSource._(dataUrl: value);

  factory ProdutoWebImageSource.url(String value) =>
      ProdutoWebImageSource._(url: value);

  static const ProdutoWebImageSource empty = ProdutoWebImageSource._();

  final String? dataUrl;
  final String? url;

  bool get hasImage => dataUrl != null || url != null;
}

class ProdutoWebImageResolver {
  const ProdutoWebImageResolver._();

  static ProdutoWebImageSource resolve(
    ProdutoImagemModel? image, {
    Uint8List? previewBytes,
    bool preferThumbnail = false,
  }) {
    if (previewBytes != null && previewBytes.isNotEmpty) {
      return ProdutoWebImageSource.dataUrl(_dataUrlFromBytes(previewBytes));
    }

    if (image == null) {
      return ProdutoWebImageSource.empty;
    }

    final List<String?> orderedUrls =
        preferThumbnail
            ? <String?>[image.urlMiniatura, image.url]
            : <String?>[image.url, image.urlMiniatura];

    for (final String? value in <String?>[image.imagemBase64, ...orderedUrls]) {
      final String? dataUrl = _tryDataUrl(value);
      if (dataUrl != null) {
        return ProdutoWebImageSource.dataUrl(dataUrl);
      }
    }

    final String? url = _firstExternalUrl(orderedUrls);
    if (url != null) {
      return ProdutoWebImageSource.url(url);
    }

    return ProdutoWebImageSource.empty;
  }

  static bool hasRenderableSource(
    ProdutoImagemModel? image, {
    bool preferThumbnail = false,
  }) {
    return resolve(image, preferThumbnail: preferThumbnail).hasImage;
  }

  static bool hasLocalDataSource(ProdutoImagemModel? image) {
    if (image == null) return false;
    return _tryDataUrl(image.imagemBase64) != null ||
        _tryDataUrl(image.url) != null ||
        _tryDataUrl(image.urlMiniatura) != null;
  }

  static String? _tryDataUrl(String? value) {
    final String? normalized = _normalizeText(value);
    if (normalized == null || _isExternalUrl(normalized)) {
      return null;
    }

    if (_isDataImageUrl(normalized)) {
      return _normalizeDataUrl(normalized);
    }

    final Uint8List? bytes = _decodeBase64(normalized);
    if (bytes == null) {
      return null;
    }

    return _dataUrlFromBytes(bytes);
  }

  static String? _normalizeDataUrl(String dataUrl) {
    final int commaIndex = dataUrl.indexOf(',');
    if (commaIndex == -1) {
      return dataUrl;
    }

    final String metadata = dataUrl.substring(5, commaIndex).toLowerCase();
    final String payload = dataUrl.substring(commaIndex + 1);
    final Uint8List? bytes = _decodeBase64(payload);
    if (bytes == null) {
      return dataUrl;
    }

    final String mimeType = metadata
        .split(';')
        .firstWhere(
          (String part) => part.startsWith('image/'),
          orElse: () => _mimeTypeFromBytes(bytes),
        );

    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  static Uint8List? _decodeBase64(String value) {
    if (_isExternalUrl(value)) {
      return null;
    }

    final String payload = value.contains(',') ? value.split(',').last : value;
    final String compact = payload
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('-', '+')
        .replaceAll('_', '/');

    if (compact.isEmpty) {
      return null;
    }

    try {
      return base64Decode(base64.normalize(compact));
    } catch (_) {
      try {
        return base64Decode(base64.normalize(Uri.decodeFull(compact)));
      } catch (_) {
        return null;
      }
    }
  }

  static String _dataUrlFromBytes(Uint8List bytes) {
    return 'data:${_mimeTypeFromBytes(bytes)};base64,${base64Encode(bytes)}';
  }

  static String _mimeTypeFromBytes(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }

    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

    if (bytes.length >= 4 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }

    return 'image/jpeg';
  }

  static String? _firstExternalUrl(Iterable<String?> values) {
    for (final String? value in values) {
      final String? normalized = _normalizeText(value);
      if (normalized != null && _isExternalUrl(normalized)) {
        return normalized;
      }
    }
    return null;
  }

  static bool _isDataImageUrl(String value) {
    return value.toLowerCase().startsWith('data:image');
  }

  static bool _isExternalUrl(String value) {
    final String lower = value.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('blob:');
  }

  static String? _normalizeText(String? value) {
    final String? normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
