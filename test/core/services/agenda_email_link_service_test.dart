import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/agenda_email_link_service.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const https = 'https://www.sixoapp.com/mobile/agenda-financeira?lang=pt';
  const native = 'com.sixoapp.app://mobile/agenda-financeira';
  late AgendaEmailLinkService service;

  setUp(() {
    service = AgendaEmailLinkService();
  });

  tearDown(() {
    binding.removeObserver(service);
    binding.platformDispatcher.clearDefaultRouteNameTestValue();
    service.dispose();
  });

  test(
    'mantém a abertura a frio até a autenticação e consome uma vez',
    () async {
      binding.platformDispatcher.defaultRouteNameTestValue = https;
      service.initialize();
      expect(service.pending, isTrue);
      expect(
        await service.didPushRouteInformation(
          RouteInformation(uri: Uri.parse(https)),
        ),
        isTrue,
      );
      expect(service.take(), isTrue);
      expect(service.take(), isFalse);
    },
  );

  test(
    'aceita a abertura pelo navegador e novos toques com o app ativo',
    () async {
      var notifications = 0;
      service.addListener(() => notifications++);
      expect(await service.didPushRoute(native), isTrue);
      expect(
        await service.didPushRouteInformation(
          RouteInformation(uri: Uri.parse(https)),
        ),
        isTrue,
      );
      expect(notifications, 1);
      expect(service.take(), isTrue);
      expect(await service.didPushRoute(AgendaEmailLinkService.path), isTrue);
      expect(notifications, 2);
    },
  );

  test(
    'deixa outros hosts, convites e retornos de assinatura para seus handlers',
    () async {
      for (final location in [
        'https://www.sixoapp.com/mobile/billing-return',
        'com.sixoapp.app://colaborador/convites/abc',
        'http://www.sixoapp.com/mobile/agenda-financeira',
        'https://www.sixoapp.com.example.org/mobile/agenda-financeira',
        'https://user@www.sixoapp.com/mobile/agenda-financeira',
        '//www.sixoapp.com/mobile/agenda-financeira',
        '/mobile/agenda-financeira/detalhe',
        'com.sixoapp.app://mobile/agenda-financeira#outra',
      ]) {
        expect(await service.didPushRoute(location), isFalse, reason: location);
      }
      expect(service.pending, isFalse);
    },
  );
}
