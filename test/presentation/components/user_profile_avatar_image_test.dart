import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/components/user_profile_avatar_image.dart';

void main() {
  group('UserProfileAvatarImageResolver', () {
    final Uint8List pngHeader = Uint8List.fromList(<int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);

    test('normaliza base64 cru como data URL de imagem', () {
      final UserProfileAvatarImageSource source =
          UserProfileAvatarImageResolver.resolve(base64Encode(pngHeader));

      expect(source.bytes, orderedEquals(pngHeader));
      expect(source.dataUrl, startsWith('data:image/png;base64,'));
      expect(source.url, isNull);
    });

    test('preserva data URL de imagem com bytes decodificados', () {
      final String dataUrl = 'data:image/png;base64,${base64Encode(pngHeader)}';

      final UserProfileAvatarImageSource source =
          UserProfileAvatarImageResolver.resolve(dataUrl);

      expect(source.bytes, orderedEquals(pngHeader));
      expect(source.dataUrl, dataUrl);
      expect(source.url, isNull);
    });

    test('mantem URL externa como fonte remota', () {
      const String imageUrl = 'https://example.com/profile.png';

      final UserProfileAvatarImageSource source =
          UserProfileAvatarImageResolver.resolve(imageUrl);

      expect(source.url, imageUrl);
      expect(source.dataUrl, isNull);
      expect(source.bytes, isNull);
    });
  });
}
