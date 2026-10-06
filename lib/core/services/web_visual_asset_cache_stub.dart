import 'dart:typed_data';

Future<Uint8List> loadWebVisualAsset(String url) =>
    Future.error(UnsupportedError('Browser cache is only available on Web'));

Future<void> removeWebVisualAsset(String url) async {}
