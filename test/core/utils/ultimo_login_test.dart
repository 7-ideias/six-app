import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/admin_portal_service.dart';
import 'package:sixpos/core/utils/ultimo_login.dart';

void main() {
  test('ausência de histórico mantém sem registro', () {
    expect(
      UltimoLogin.fromInstant(null, timeZone: 'America/Sao_Paulo').recencia,
      UltimoLoginRecencia.semRegistro,
    );
    expect(AdminUsuarioEmpresaAtiva.fromJson({}).ultimoLoginEm, isNull);
    expect(
      AdminUsuarioEmpresaAtiva.fromJson({
        'ultimoLoginEm': 'inválido',
      }).ultimoLoginEm,
      isNull,
    );
  });

  test('preserva o instante UTC e exibe no fuso configurado', () {
    final user = AdminUsuarioEmpresaAtiva.fromJson({
      'ultimoLoginEm': '2026-11-06T01:30:00Z',
    });
    final login = UltimoLogin.fromInstant(
      user.ultimoLoginEm,
      timeZone: 'America/Sao_Paulo',
      now: DateTime.utc(2026, 11, 6, 15),
    );
    expect(user.ultimoLoginEm!.isUtc, isTrue);
    expect(login.data!.day, 5);
    expect(login.data!.hour, 22);
    expect(login.dias, 1);
    expect(login.recencia, UltimoLoginRecencia.recente);
  });

  test('recência distingue hoje, últimos sete dias e registros antigos', () {
    final now = DateTime.utc(2026, 11, 6, 12);
    for (final entry in {
      0: UltimoLoginRecencia.hoje,
      1: UltimoLoginRecencia.recente,
      7: UltimoLoginRecencia.recente,
      8: UltimoLoginRecencia.antigo,
    }.entries) {
      expect(
        UltimoLogin.fromInstant(
          now.subtract(Duration(days: entry.key)),
          timeZone: 'UTC',
          now: now,
        ).recencia,
        entry.value,
      );
    }
  });

  test('usa dias de calendário mesmo na mudança do horário de verão', () {
    final login = UltimoLogin.fromInstant(
      DateTime.utc(2026, 3, 28, 23, 30),
      timeZone: 'Europe/London',
      now: DateTime.utc(2026, 3, 29, 22, 30),
    );
    expect(login.dias, 1);
    expect(login.data!.day, 28);
  });
}
