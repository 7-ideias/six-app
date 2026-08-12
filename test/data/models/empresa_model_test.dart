import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/empresa_model.dart';

void main() {
  test('EmpresaModel parseia horarios de atendimento estruturados', () {
    final EmpresaModel empresa = EmpresaModel.fromJson(<String, dynamic>{
      'nomeEmpresa': 'Empresa',
      'nomeFantasia': 'Fantasia',
      'documentoNoBrasilCNPJ': '123',
      'horariosAtendimento': <Map<String, dynamic>>[
        <String, dynamic>{
          'diaSemana': 'MONDAY',
          'fechado': false,
          'inicio': '08:00',
          'fim': '18:00',
        },
        <String, dynamic>{'diaSemana': 'SUNDAY', 'fechado': true},
      ],
    });

    expect(empresa.horariosAtendimento, hasLength(2));
    expect(empresa.horariosAtendimento.first.diaSemana, 'MONDAY');
    expect(empresa.horariosAtendimento.first.inicio, '08:00');
    expect(empresa.horariosAtendimento.last.fechado, isTrue);
  });

  test(
    'EmpresaModel omite horarios vazios para preservar clientes antigos',
    () {
      final Map<String, dynamic> json =
          const EmpresaModel(
            nomeEmpresa: 'Empresa',
            nomeFantasia: 'Fantasia',
            documentoNoBrasilCNPJ: '123',
          ).toJson();

      expect(json.containsKey('horariosAtendimento'), isFalse);
    },
  );

  test('EmpresaModel envia horarios quando configurados', () {
    final Map<String, dynamic> json =
        const EmpresaModel(
          nomeEmpresa: 'Empresa',
          nomeFantasia: 'Fantasia',
          documentoNoBrasilCNPJ: '123',
          horariosAtendimento: <HorarioAtendimentoModel>[
            HorarioAtendimentoModel(
              diaSemana: 'MONDAY',
              fechado: false,
              inicio: '08:00',
              fim: '18:00',
            ),
            HorarioAtendimentoModel(diaSemana: 'SUNDAY', fechado: true),
          ],
        ).toJson();

    expect(json['horariosAtendimento'], isA<List<dynamic>>());
    final List<dynamic> horarios = json['horariosAtendimento'] as List<dynamic>;
    expect(horarios.first, containsPair('inicio', '08:00'));
    expect(horarios.last, isNot(contains('inicio')));
  });
}
