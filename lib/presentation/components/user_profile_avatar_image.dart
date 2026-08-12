import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

class UserProfileAvatarImage extends StatelessWidget {
  const UserProfileAvatarImage({
    super.key,
    required this.imageValue,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.size,
    this.fallbackIconSize,
    this.fit = BoxFit.cover,
    this.circle = false,
  });

  final String? imageValue;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double? size;
  final double? fallbackIconSize;
  final BoxFit fit;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final UserProfileAvatarImageSource source =
        UserProfileAvatarImageResolver.resolve(imageValue);

    if (!source.hasImage) {
      return _fallback();
    }

    if (!kIsWeb && source.bytes != null) {
      return _imageContainer(MemoryImage(source.bytes!));
    }

    final String? imageUrl = source.dataUrl ?? source.url;
    if (imageUrl == null) {
      return _fallback();
    }

    if (!kIsWeb) {
      return _NativeNetworkProfileImage(
        imageUrl: imageUrl,
        size: size,
        fit: fit,
        circle: circle,
        fallback: _fallback(),
      );
    }

    return _NetworkProfileImage(
      imageUrl: imageUrl,
      size: size,
      fit: fit,
      circle: circle,
      fallback: _fallback(),
      webHtmlElementStrategy:
          source.dataUrl != null
              ? WebHtmlElementStrategy.prefer
              : WebHtmlElementStrategy.fallback,
    );
  }

  Widget _imageContainer(ImageProvider imageProvider) {
    if (!circle) {
      return Image(
        image: imageProvider,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(image: imageProvider, fit: fit),
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Icon(
        fallbackIcon,
        size: fallbackIconSize ?? size,
        color: fallbackColor,
      ),
    );
  }
}

class UserProfileAvatarImageSource {
  const UserProfileAvatarImageSource._({this.dataUrl, this.url, this.bytes});

  factory UserProfileAvatarImageSource.dataUrl(
    String dataUrl,
    Uint8List? bytes,
  ) {
    return UserProfileAvatarImageSource._(dataUrl: dataUrl, bytes: bytes);
  }

  factory UserProfileAvatarImageSource.url(String value) {
    return UserProfileAvatarImageSource._(url: value);
  }

  static const UserProfileAvatarImageSource empty =
      UserProfileAvatarImageSource._();

  final String? dataUrl;
  final String? url;
  final Uint8List? bytes;

  bool get hasImage => dataUrl != null || url != null || bytes != null;
}

class UserProfileAvatarImageResolver {
  const UserProfileAvatarImageResolver._();

  static UserProfileAvatarImageSource resolve(String? value) {
    final String normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return UserProfileAvatarImageSource.empty;
    }

    if (_isDataImageUrl(normalized)) {
      return _sourceFromDataUrl(normalized);
    }

    final Uint8List? bytes = _decodeBase64Image(normalized);
    if (bytes != null) {
      return UserProfileAvatarImageSource.dataUrl(
        _dataUrlFromBytes(bytes),
        bytes,
      );
    }

    return UserProfileAvatarImageSource.url(_resolveUrl(normalized));
  }

  static UserProfileAvatarImageSource _sourceFromDataUrl(String dataUrl) {
    final int commaIndex = dataUrl.indexOf(',');
    if (commaIndex == -1) {
      return UserProfileAvatarImageSource.dataUrl(dataUrl, null);
    }

    final String metadata = dataUrl.substring(5, commaIndex).toLowerCase();
    final String payload = dataUrl.substring(commaIndex + 1);
    final Uint8List? bytes = _decodeBase64Image(payload);
    if (bytes == null) {
      return UserProfileAvatarImageSource.dataUrl(dataUrl, null);
    }

    final String mimeType = metadata
        .split(';')
        .firstWhere(
          (String part) => part.startsWith('image/'),
          orElse: () => _mimeTypeFromBytes(bytes),
        );

    return UserProfileAvatarImageSource.dataUrl(
      'data:$mimeType;base64,${base64Encode(bytes)}',
      bytes,
    );
  }

  static Uint8List? _decodeBase64Image(String value) {
    String payload = value.trim();
    final String lowerValue = payload.toLowerCase();
    if (lowerValue.startsWith('data:') && payload.contains(',')) {
      payload = payload.substring(payload.indexOf(',') + 1);
    }

    try {
      return _decodeNormalizedBase64(payload);
    } catch (_) {
      try {
        return _decodeNormalizedBase64(Uri.decodeFull(payload));
      } catch (_) {
        return null;
      }
    }
  }

  static Uint8List _decodeNormalizedBase64(String payload) {
    final String normalized = base64.normalize(
      payload
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll('-', '+')
          .replaceAll('_', '/'),
    );
    return base64Decode(normalized);
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

    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'image/gif';
    }

    return 'image/jpeg';
  }

  static bool _isDataImageUrl(String value) {
    return value.toLowerCase().startsWith('data:image/');
  }

  static String _resolveUrl(String value) {
    if (!value.startsWith('/')) {
      return value;
    }

    final String baseUrl = AppConfig.baseUrl;
    if (baseUrl.isEmpty) {
      return value;
    }

    return '${baseUrl.replaceFirst(RegExp(r'/$'), '')}$value';
  }
}

class _NativeNetworkProfileImage extends StatelessWidget {
  const _NativeNetworkProfileImage({
    required this.imageUrl,
    required this.fallback,
    this.size,
    this.fit = BoxFit.cover,
    this.circle = false,
  });

  final String imageUrl;
  final Widget fallback;
  final double? size;
  final BoxFit fit;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    if (!circle) {
      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: fit,
      frameBuilder: (
        BuildContext context,
        Widget child,
        int? frame,
        bool wasSynchronouslyLoaded,
      ) {
        if (frame == null && !wasSynchronouslyLoaded) {
          return fallback;
        }
        return ClipOval(
          child: SizedBox(width: size, height: size, child: child),
        );
      },
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _NetworkProfileImage extends StatelessWidget {
  const _NetworkProfileImage({
    required this.imageUrl,
    required this.fallback,
    this.size,
    this.fit = BoxFit.cover,
    this.circle = false,
    required this.webHtmlElementStrategy,
  });

  final String imageUrl;
  final Widget fallback;
  final double? size;
  final BoxFit fit;
  final bool circle;
  final WebHtmlElementStrategy webHtmlElementStrategy;

  @override
  Widget build(BuildContext context) {
    final Widget image = Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: fit,
      gaplessPlayback: true,
      webHtmlElementStrategy: webHtmlElementStrategy,
      loadingBuilder: (
        BuildContext context,
        Widget child,
        ImageChunkEvent? loadingProgress,
      ) {
        if (loadingProgress == null) return child;
        return fallback;
      },
      errorBuilder: (_, _, _) => fallback,
    );

    if (!circle) {
      return image;
    }

    return ClipOval(child: SizedBox(width: size, height: size, child: image));
  }
}
