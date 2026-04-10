import 'dart:typed_data';

import 'pdf_download_stub.dart'
    if (dart.library.html) 'pdf_download_web.dart' as pdf_download_impl;

bool iniciarDownloadPdf({
  required Uint8List bytes,
  required String nomeArquivo,
  required String mimeType,
}) {
  return pdf_download_impl.iniciarDownloadPdf(
    bytes: bytes,
    nomeArquivo: nomeArquivo,
    mimeType: mimeType,
  );
}
