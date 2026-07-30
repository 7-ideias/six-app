import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_response_type_metadata.dart';

void main() {
  test('metadata covers every procedure response type', () {
    for (final ProcedureResponseType type in ProcedureResponseType.values) {
      expect(metadataForResponseType(type).type, type);
    }
  });

  test('choice and simulated capabilities are centralized', () {
    expect(isChoiceResponseType(ProcedureResponseType.singleChoice), isTrue);
    expect(isChoiceResponseType(ProcedureResponseType.multipleChoice), isTrue);
    expect(isChoiceResponseType(ProcedureResponseType.confirmation), isFalse);

    expect(isSimulatedResponseType(ProcedureResponseType.photo), isTrue);
    expect(isSimulatedResponseType(ProcedureResponseType.signature), isTrue);
    expect(isSimulatedResponseType(ProcedureResponseType.location), isTrue);
    expect(isSimulatedResponseType(ProcedureResponseType.barcode), isTrue);
    expect(isSimulatedResponseType(ProcedureResponseType.document), isTrue);
    expect(isSimulatedResponseType(ProcedureResponseType.audio), isTrue);
    expect(isSimulatedResponseType(ProcedureResponseType.imei), isFalse);
  });
}
