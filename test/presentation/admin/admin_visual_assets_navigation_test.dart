import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/admin/admin_navigation_shell.dart';

void main() {
  test('menu de imagens é exclusivo do perfil SUPER', () {
    expect(adminVisualAssetsVisibleForProfile('SUPER'), isTrue);
    expect(adminVisualAssetsVisibleForProfile(' super '), isTrue);

    for (final String? profile in <String?>[
      'ADMIN',
      'COLABORADOR',
      'CLIENTE',
      '',
      null,
    ]) {
      expect(
        adminVisualAssetsVisibleForProfile(profile),
        isFalse,
        reason: 'perfil=$profile',
      );
    }
  });
}
