import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart' as sharing;

import '../../data/models/atendimento_tecnico_models.dart';

enum PdfFileShareDisposition { shared, downloaded }

enum PdfFileShareFailure {
  invalidMimeType,
  emptyBase64,
  invalidBase64,
  emptyFile,
  invalidPdfSignature,
  shareUnavailable,
}

class PdfFileShareResult {
  const PdfFileShareResult({
    required this.disposition,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });

  final PdfFileShareDisposition disposition;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
}

class PdfFileShareException implements Exception {
  const PdfFileShareException(this.failure, [this.cause]);

  final PdfFileShareFailure failure;
  final Object? cause;

  @override
  String toString() => 'PdfFileShareException($failure)';
}

abstract class PdfFileShareAdapter {
  Future<PdfFileShareResult> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    Rect? sharePositionOrigin,
  });
}

class SharePlusPdfFileShareAdapter implements PdfFileShareAdapter {
  const SharePlusPdfFileShareAdapter();

  @override
  Future<PdfFileShareResult> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    Rect? sharePositionOrigin,
  }) async {
    try {
      sharing.Share.downloadFallbackEnabled = true;
      final sharing.ShareResult result = await sharing.Share.shareXFiles(
        <sharing.XFile>[
          sharing.XFile.fromData(bytes, name: fileName, mimeType: mimeType),
        ],
        subject: fileName,
        sharePositionOrigin: sharePositionOrigin,
        fileNameOverrides: <String>[fileName],
      );
      return PdfFileShareResult(
        disposition:
            kIsWeb && result.status == sharing.ShareResultStatus.unavailable
                ? PdfFileShareDisposition.downloaded
                : PdfFileShareDisposition.shared,
        fileName: fileName,
        mimeType: mimeType,
        sizeBytes: bytes.length,
      );
    } catch (error) {
      throw PdfFileShareException(PdfFileShareFailure.shareUnavailable, error);
    }
  }
}

class PdfFileShareService {
  const PdfFileShareService({PdfFileShareAdapter? adapter})
    : _adapter = adapter ?? const SharePlusPdfFileShareAdapter();

  final PdfFileShareAdapter _adapter;

  Future<PdfFileShareResult> sharePdfResponse(
    AtendimentoTecnicoPdfResponseModel response, {
    Rect? sharePositionOrigin,
  }) async {
    final String mimeType = response.mimeType.trim().toLowerCase();
    if (mimeType != 'application/pdf') {
      throw const PdfFileShareException(PdfFileShareFailure.invalidMimeType);
    }

    final String base64Payload = response.base64.replaceAll(RegExp(r'\s+'), '');
    if (base64Payload.isEmpty) {
      throw const PdfFileShareException(PdfFileShareFailure.emptyBase64);
    }

    final Uint8List bytes;
    try {
      bytes = base64Decode(base64Payload);
    } catch (error) {
      throw PdfFileShareException(PdfFileShareFailure.invalidBase64, error);
    }

    if (bytes.isEmpty) {
      throw const PdfFileShareException(PdfFileShareFailure.emptyFile);
    }
    if (!_hasPdfSignature(bytes)) {
      throw const PdfFileShareException(
        PdfFileShareFailure.invalidPdfSignature,
      );
    }

    return _adapter.sharePdf(
      bytes: bytes,
      fileName: _safeFileName(response.fileName),
      mimeType: mimeType,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  bool _hasPdfSignature(Uint8List bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }

  String _safeFileName(String fileName) {
    final String normalized = fileName.trim().replaceAll(
      RegExp(r'[^A-Za-z0-9._-]+'),
      '-',
    );
    final String withoutEdges = normalized
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
    if (withoutEdges.toLowerCase().endsWith('.pdf') &&
        withoutEdges.length > 4) {
      return withoutEdges;
    }
    final String base =
        withoutEdges.isEmpty ? 'atendimento-tecnico' : withoutEdges;
    return '$base.pdf';
  }
}
