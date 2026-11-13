import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/utils/company_time.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

class _Regionalizacao implements RegionalizacaoService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'formulários usam o dia da empresa e enviam datas civis sem offset',
    () async {
      final provider = LocaleSettingsProvider(
        regionalizacaoService: _Regionalizacao(),
        now: () => DateTime.parse('2026-11-13T01:30:00Z'),
      );
      addTearDown(provider.dispose);
      expect(provider.calendarNow, DateTime(2026, 11, 12, 22, 30));
      expect(provider.calendarNow.toIso8601String(), '2026-11-12T22:30:00.000');
      await provider.atualizarConfiguracaoDaEmpresa(
        provider.companyConfig.copyWith(
          formatting: provider.companyConfig.formatting.copyWith(
            timeZone: 'Asia/Tokyo',
          ),
        ),
      );
      expect(provider.calendarNow, DateTime(2026, 11, 13, 10, 30));
      expect(
        provider.nowInCompany.toUtc(),
        DateTime.parse('2026-11-13T01:30:00Z'),
      );
    },
  );

  test('metadados antigos ausentes ou inválidos não quebram a consulta', () {
    expect(CompanyTime.tryParse(null), isNull);
    expect(CompanyTime.tryParse(''), isNull);
    expect(CompanyTime.tryParse('sem data'), isNull);
    expect(CompanyTime.tryParse({'formato': 'antigo'}), isNull);
    expect(CompanyTime.tryParse('2026-11-12T19:50:00')?.hour, 19);
    expect(CompanyTime.tryParse('2026-11-12T19:50:00-03:00')?.isUtc, isTrue);
  });

  test(
    'configuração antiga inválida usa UTC sem consultar o fuso do aparelho',
    () {
      final instant = DateTime.parse('2026-11-12T22:50:00Z');
      expect(CompanyTime.fromInstant(instant, 'fuso-antigo').hour, 22);
    },
  );

  test('duração do caixa interpreta resposta local pelo fuso da empresa', () {
    final legacyCompany = DateTime.parse('2026-11-12T19:50:00');
    final utc = DateTime.parse('2026-11-12T22:50:00Z');
    expect(CompanyTime.toInstant(legacyCompany, 'America/Sao_Paulo'), utc);
    expect(CompanyTime.toInstant(utc, 'Asia/Tokyo'), utc);
    final now = DateTime.parse('2026-11-13T00:20:00Z');
    expect(
      now.difference(CompanyTime.toInstant(legacyCompany, 'America/Sao_Paulo')),
      const Duration(hours: 1, minutes: 30),
    );
  });

  test('19h50 usa o fuso da empresa para Z e offset explícito', () {
    final provider = LocaleSettingsProvider(
      regionalizacaoService: _Regionalizacao(),
    );
    addTearDown(provider.dispose);
    for (final value in [
      '2026-11-12T22:50:05.636Z',
      '2026-11-12T19:50:05.636-03:00',
    ]) {
      expect(provider.formatTime(DateTime.parse(value)), '19:50');
      expect(provider.formatDate(DateTime.parse(value)), '12/11/2026');
    }
  });

  test(
    'virada de dia e troca de empresa reformatam o mesmo instante',
    () async {
      final provider = LocaleSettingsProvider(
        regionalizacaoService: _Regionalizacao(),
      );
      addTearDown(provider.dispose);
      final instant = DateTime.parse('2026-11-13T01:30:00Z');
      expect(provider.formatDate(instant), '12/11/2026');
      expect(provider.formatTime(instant), '22:30');
      await provider.atualizarConfiguracaoDaEmpresa(
        provider.companyConfig.copyWith(
          formatting: provider.companyConfig.formatting.copyWith(
            timeZone: 'Europe/Warsaw',
          ),
        ),
      );
      expect(provider.formatDate(instant), '13/11/2026');
      expect(provider.formatTime(instant), '02:30');
    },
  );

  test('datas civis e contrato legado sem offset não sofrem conversão', () {
    final civil = DateTime(2026, 11, 12);
    final legacy = DateTime.parse('2026-11-12T19:50:00');
    expect(CompanyTime.forDisplay(civil, 'America/New_York'), same(civil));
    expect(CompanyTime.forDisplay(legacy, 'America/New_York'), same(legacy));
  });

  test(
    'conversão não usa o fuso do aparelho nem aplica desconto duas vezes',
    () {
      final instant = DateTime.parse('2026-11-12T22:50:05Z');
      final localDevice = instant.toLocal();
      final company = CompanyTime.fromInstant(localDevice, 'America/Sao_Paulo');
      expect(company.hour, 19);
      expect(CompanyTime.forDisplay(company, 'America/Sao_Paulo').hour, 19);
      expect(company.toUtc(), instant);
    },
  );

  test('IANA respeita horário de verão e offsets fracionários', () {
    expect(
      CompanyTime.fromInstant(
        DateTime.parse('2026-01-12T22:50:00Z'),
        'America/New_York',
      ).hour,
      17,
    );
    expect(
      CompanyTime.fromInstant(
        DateTime.parse('2026-07-12T22:50:00Z'),
        'America/New_York',
      ).hour,
      18,
    );
    final kathmandu = CompanyTime.fromInstant(
      DateTime.parse('2026-11-12T22:50:00Z'),
      'Asia/Kathmandu',
    );
    expect(kathmandu.day, 13);
    expect(kathmandu.hour, 4);
    expect(kathmandu.minute, 35);
  });
}
