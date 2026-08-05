import 'dart:convert';
import 'dart:typed_data';

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
    final String value = imageValue?.trim() ?? '';
    if (value.isEmpty) {
      return _fallback();
    }

    final Uint8List? memoryImage = _decodeBase64Image(value);
    if (memoryImage != null) {
      return _imageContainer(MemoryImage(memoryImage));
    }

    final String imageUrl = _resolveUrl(value);
    return _NetworkProfileImage(
      imageUrl: imageUrl,
      size: size,
      fit: fit,
      circle: circle,
      fallback: _fallback(),
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

  Uint8List? _decodeBase64Image(String value) {
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

  Uint8List _decodeNormalizedBase64(String payload) {
    final String normalized = base64.normalize(
      payload
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll('-', '+')
          .replaceAll('_', '/'),
    );
    return base64Decode(normalized);
  }

  String _resolveUrl(String value) {
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

class _NetworkProfileImage extends StatelessWidget {
  const _NetworkProfileImage({
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
