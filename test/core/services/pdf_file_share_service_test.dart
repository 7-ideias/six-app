import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/pdf_file_share_service.dart';
import 'package:sixpos/data/models/atendimento_tecnico_models.dart';

void main() {
  test('decodes pdf base64 and preserves file metadata', () async {
    final _FakePdfFileShareAdapter adapter = _FakePdfFileShareAdapter();
    final PdfFileShareService service = PdfFileShareService(adapter: adapter);

    final PdfFileShareResult result = await service.sharePdfResponse(
      AtendimentoTecnicoPdfResponseModel(
        fileName: 'atendimento técnico AT/123.pdf',
        mimeType: 'application/pdf',
        base64: base64Encode(Uint8List.fromList('%PDF-1.4\nbody'.codeUnits)),
        sizeBytes: 13,
      ),
      sharePositionOrigin: const Rect.fromLTWH(1, 2, 44, 44),
    );

    expect(result.disposition, PdfFileShareDisposition.shared);
    expect(adapter.calls, 1);
    expect(adapter.lastFileName, 'atendimento-t-cnico-AT-123.pdf');
    expect(adapter.lastMimeType, 'application/pdf');
    expect(adapter.lastBytes, Uint8List.fromList('%PDF-1.4\nbody'.codeUnits));
    expect(adapter.lastSharePositionOrigin, const Rect.fromLTWH(1, 2, 44, 44));
  });

  test('does not share invalid base64 payload', () async {
    final _FakePdfFileShareAdapter adapter = _FakePdfFileShareAdapter();
    final PdfFileShareService service = PdfFileShareService(adapter: adapter);

    expect(
      () => service.sharePdfResponse(
        const AtendimentoTecnicoPdfResponseModel(
          fileName: 'atendimento.pdf',
          mimeType: 'application/pdf',
          base64: 'invalid-base64',
          sizeBytes: 0,
        ),
      ),
      throwsA(
        isA<PdfFileShareException>().having(
          (PdfFileShareException error) => error.failure,
          'failure',
          PdfFileShareFailure.invalidBase64,
        ),
      ),
    );
    expect(adapter.calls, 0);
  });

  test('rejects unexpected mime type and non pdf bytes', () async {
    final _FakePdfFileShareAdapter adapter = _FakePdfFileShareAdapter();
    final PdfFileShareService service = PdfFileShareService(adapter: adapter);

    await expectLater(
      service.sharePdfResponse(
        const AtendimentoTecnicoPdfResponseModel(
          fileName: 'atendimento.pdf',
          mimeType: 'text/plain',
          base64: 'JVBERi0xLjQK',
          sizeBytes: 9,
        ),
      ),
      throwsA(
        isA<PdfFileShareException>().having(
          (PdfFileShareException error) => error.failure,
          'failure',
          PdfFileShareFailure.invalidMimeType,
        ),
      ),
    );

    await expectLater(
      service.sharePdfResponse(
        AtendimentoTecnicoPdfResponseModel(
          fileName: 'atendimento.pdf',
          mimeType: 'application/pdf',
          base64: base64Encode(Uint8List.fromList('not-pdf'.codeUnits)),
          sizeBytes: 7,
        ),
      ),
      throwsA(
        isA<PdfFileShareException>().having(
          (PdfFileShareException error) => error.failure,
          'failure',
          PdfFileShareFailure.invalidPdfSignature,
        ),
      ),
    );
    expect(adapter.calls, 0);
  });

  test('propagates download fallback disposition from adapter', () async {
    final _FakePdfFileShareAdapter adapter = _FakePdfFileShareAdapter(
      disposition: PdfFileShareDisposition.downloaded,
    );
    final PdfFileShareService service = PdfFileShareService(adapter: adapter);

    final PdfFileShareResult result = await service.sharePdfResponse(
      AtendimentoTecnicoPdfResponseModel(
        fileName: 'atendimento.pdf',
        mimeType: 'application/pdf',
        base64: base64Encode(Uint8List.fromList('%PDF-1.4\nbody'.codeUnits)),
        sizeBytes: 13,
      ),
    );

    expect(result.disposition, PdfFileShareDisposition.downloaded);
    expect(result.fileName, 'atendimento.pdf');
  });
}

class _FakePdfFileShareAdapter implements PdfFileShareAdapter {
  _FakePdfFileShareAdapter({this.disposition = PdfFileShareDisposition.shared});

  final PdfFileShareDisposition disposition;

  int calls = 0;
  Uint8List? lastBytes;
  String? lastFileName;
  String? lastMimeType;
  Rect? lastSharePositionOrigin;

  @override
  Future<PdfFileShareResult> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    Rect? sharePositionOrigin,
  }) async {
    calls++;
    lastBytes = bytes;
    lastFileName = fileName;
    lastMimeType = mimeType;
    lastSharePositionOrigin = sharePositionOrigin;
    return PdfFileShareResult(
      disposition: disposition,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: bytes.length,
    );
  }
}
