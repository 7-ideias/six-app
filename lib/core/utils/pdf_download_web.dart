import 'dart:html' as html;
import 'dart:typed_data';

bool iniciarDownloadPdf({
  required Uint8List bytes,
  required String nomeArquivo,
  required String mimeType,
}) {
  final html.Blob blob = html.Blob(<dynamic>[bytes], mimeType);
  final String url = html.Url.createObjectUrlFromBlob(blob);
  final html.AnchorElement anchor = html.AnchorElement(href: url)
    ..download = nomeArquivo
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);

  return true;
}
