import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/navigation/web_auth_route_utils.dart';

void main() {
  group('web auth route utils', () {
    test('protege /app e rotas abaixo de /app', () {
      expect(isAuthenticatedWebAppRoute(Uri.parse('/app')), isTrue);
      expect(
        isAuthenticatedWebAppRoute(
          Uri.parse('/app/atendimentos-tecnicos/criados'),
        ),
        isTrue,
      );
      expect(
        normalizeAuthenticatedWebLocation('/app/financeiro?periodo=mes'),
        '/app/financeiro?periodo=mes',
      );
    });

    test('mantem rotas publicas fora do WebAuthGate', () {
      for (final String route in <String>[
        '/',
        '/home',
        '/login',
        '/login/flutter',
        '/register',
        '/register/flutter',
        '/forgot-password',
        '/forgot-password/flutter',
        '/onboarding',
        '/onboarding/flutter',
        '/checkout',
        '/checkout/flutter',
        '/ordem-servico/123',
        '/cliente/auto-cadastro/abc',
        '/colaborador/convites/abc',
        '/atendimento/status',
        '/atendimento/assinatura',
      ]) {
        expect(isAuthenticatedWebAppRoute(Uri.parse(route)), isFalse);
      }
    });

    test('nao protege admin nesta etapa', () {
      expect(isAuthenticatedWebAppRoute(Uri.parse('/admin')), isFalse);
      expect(
        isAuthenticatedWebAppRoute(Uri.parse('/admin/dashboard')),
        isFalse,
      );
    });

    test('redirect de login preserva deep link interno autenticado', () {
      expect(
        buildLoginRouteForAuthenticatedWebRedirect(
          '/app/atendimentos-tecnicos?tab=criados#historico',
        ),
        '/login?redirect=%2Fapp%2Fatendimentos-tecnicos%3Ftab%3Dcriados%23historico',
      );
    });

    test('redirect rejeita open redirect e rotas publicas', () {
      expect(
        sanitizeAuthenticatedWebRedirect('https://site-malicioso.com/app'),
        isNull,
      );
      expect(
        sanitizeAuthenticatedWebRedirect('//site-malicioso.com/app'),
        isNull,
      );
      expect(sanitizeAuthenticatedWebRedirect('/login'), isNull);
      expect(sanitizeAuthenticatedWebRedirect('/login/flutter'), isNull);
      expect(sanitizeAuthenticatedWebRedirect('/register'), isNull);
      expect(sanitizeAuthenticatedWebRedirect('/forgot-password'), isNull);
      expect(sanitizeAuthenticatedWebRedirect('/admin'), isNull);
      expect(sanitizeAuthenticatedWebRedirect('/app'), '/app');
      expect(
        sanitizeAuthenticatedWebRedirect('/app/financeiro?periodo=mes#saldo'),
        '/app/financeiro?periodo=mes#saldo',
      );
      expect(sanitizeAuthenticatedWebRedirect('/app\\admin'), isNull);
      expect(sanitizeAuthenticatedWebRedirect('/app%5Cadmin'), isNull);
      expect(sanitizeAuthenticatedWebRedirect('/app/../admin'), isNull);
    });
  });
}
