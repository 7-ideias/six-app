import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/push_destination_resolver.dart';
import 'package:sixpos/core/services/push_campaign_service.dart';

void main() {
  test('campanha resolve assinatura preservando empresa e identificador', () {
    final resolved = const PushDestinationResolver().resolve(
      PushNavigationIntent(
        payload: {
          'destination': 'billing.subscription',
          'campaignId': 'campaign',
          'eventId': 'campaign:admin',
          'idUnicoDaEmpresa': 'company',
        },
        source: PushNavigationSource.firebaseInitialMessage,
      ),
    );
    expect(resolved.destination, PushNavigationDestination.subscription);
    expect(resolved.payload['idUnicoDaEmpresa'], 'company');
    expect(resolved.intent.dedupKey, 'campaign:admin');
    expect(resolved.shellTab, isNull);
  });
  test('selecao preserva usuario e empresa e informa falta de dispositivo', () {
    final recipient = CampaignRecipient.fromJson({
      'usuarioId': 'admin',
      'empresaId': 'company',
      'idioma': 'es',
      'assinatura': 'TRIAL',
      'dispositivos': 0,
    });
    expect(recipient.selection, {'usuarioId': 'admin', 'empresaId': 'company'});
    expect(recipient.language, 'es');
    expect(recipient.devices, 0);
  });
}
