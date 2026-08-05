import 'dart:convert';

import 'package:image_picker/image_picker.dart';

Future<String> buildProfileImageDataUrl(XFile file) async {
  final List<int> bytes = await file.readAsBytes();
  if (bytes.isEmpty) {
    throw const FormatException('Imagem vazia.');
  }

  final String mimeType =
      file.mimeType ?? _mimeTypeFromName(file.name) ?? 'image/jpeg';
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

String? _mimeTypeFromName(String name) {
  final String lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.heic')) return 'image/heic';
  if (lower.endsWith('.heif')) return 'image/heif';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return null;
}
