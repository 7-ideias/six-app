import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/l10n/six_i18n.dart';

void main() {
  test('normaliza aliases visíveis antigos para SixoApp', () {
    expect(normalizeSixoAppBranding('Six'), 'SixoApp');
    expect(normalizeSixoAppBranding('SixApp'), 'SixoApp');
    expect(normalizeSixoAppBranding('Six App'), 'SixoApp');
    expect(normalizeSixoAppBranding('Six POS com IA'), 'SixoApp com IA');
    expect(normalizeSixoAppBranding('Six ERP IA'), 'SixoApp IA');
    expect(normalizeSixoAppBranding('Appplanilha'), 'SixoApp');
  });

  test('preserva identificadores técnicos de compatibilidade', () {
    expect(normalizeSixoAppBranding('SixBack'), 'SixBack');
    expect(
      normalizeSixoAppBranding('https://api.sixappback.com'),
      'https://api.sixappback.com',
    );
    expect(normalizeSixoAppBranding('X-Six-Timezone'), 'X-Six-Timezone');
  });
}
