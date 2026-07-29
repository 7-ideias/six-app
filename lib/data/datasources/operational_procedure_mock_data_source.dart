import 'package:sixpos/data/models/operational_procedure_models.dart';

enum OperationalProcedureMockScenario { success, empty, error }

class OperationalProcedureMockDataSource {
  const OperationalProcedureMockDataSource({
    this.scenario = OperationalProcedureMockScenario.success,
    this.delay = const Duration(milliseconds: 520),
  });

  final OperationalProcedureMockScenario scenario;
  final Duration delay;

  Future<OperationalProcedureSummary> fetchProcedures() async {
    await Future<void>.delayed(delay);

    switch (scenario) {
      case OperationalProcedureMockScenario.empty:
        return const OperationalProcedureSummary(
          procedures: <OperationalProcedure>[],
        );
      case OperationalProcedureMockScenario.error:
        throw const OperationalProcedureMockException();
      case OperationalProcedureMockScenario.success:
        return OperationalProcedureSummary(
          procedures: <OperationalProcedure>[
            OperationalProcedure(
              id: 'device-intake',
              name: 'Recepção de aparelho',
              description:
                  'Conferência inicial de itens, acessórios e avarias.',
              operationType: ProcedureOperationType.technicalService,
              moment: ProcedureMoment.beforeStart,
              status: ProcedureStatus.active,
              required: true,
              stages: <ProcedureStage>[
                _stage(
                  id: 'device-intake-check',
                  order: 1,
                  title: 'Conferência do aparelho',
                  description:
                      'Verifique itens e condições antes de abrir o atendimento.',
                  items: <ProcedureItem>[
                    _item(
                      'device-intake-chip',
                      1,
                      'O aparelho possui chip?',
                      ProcedureResponseType.yesNo,
                    ),
                    _item(
                      'device-intake-case',
                      2,
                      'O aparelho possui capinha?',
                      ProcedureResponseType.yesNo,
                    ),
                    _item(
                      'device-intake-damage',
                      3,
                      'Registrar avarias visíveis.',
                      ProcedureResponseType.confirmation,
                    ),
                  ],
                ),
                _stage(
                  id: 'device-intake-customer',
                  order: 2,
                  title: 'Orientações ao cliente',
                  items: <ProcedureItem>[
                    _item(
                      'device-intake-photos',
                      1,
                      'Confirmar que foram tiradas fotos.',
                      ProcedureResponseType.confirmation,
                    ),
                    _item(
                      'device-intake-deadline',
                      2,
                      'Informe ao cliente o prazo estimado do reparo.',
                      ProcedureResponseType.instruction,
                      required: false,
                    ),
                  ],
                ),
              ],
              createdAt: DateTime(2026, 7, 22, 10),
              updatedAt: DateTime(2026, 7, 22, 10, 30),
            ),
            OperationalProcedure(
              id: 'service-order-closing',
              name: 'Fechamento de ordem de serviço',
              description:
                  'Validação de testes e informações antes de concluir.',
              operationType: ProcedureOperationType.technicalService,
              moment: ProcedureMoment.beforeFinish,
              status: ProcedureStatus.active,
              required: true,
              stages: <ProcedureStage>[
                _stage(
                  id: 'service-order-closing-tests',
                  order: 1,
                  title: 'Testes finais',
                  items: <ProcedureItem>[
                    _item(
                      'service-order-closing-screen',
                      1,
                      'Tela e toque foram testados?',
                      ProcedureResponseType.yesNo,
                    ),
                    _item(
                      'service-order-closing-charge',
                      2,
                      'Carregamento foi validado?',
                      ProcedureResponseType.confirmation,
                    ),
                  ],
                ),
                _stage(
                  id: 'service-order-closing-review',
                  order: 2,
                  title: 'Revisão de conclusão',
                  items: <ProcedureItem>[
                    _item(
                      'service-order-closing-notes',
                      1,
                      'Informações da OS foram revisadas?',
                      ProcedureResponseType.confirmation,
                    ),
                    _item(
                      'service-order-closing-customer',
                      2,
                      'Cliente foi avisado sobre a conclusão?',
                      ProcedureResponseType.confirmation,
                    ),
                  ],
                ),
              ],
              createdAt: DateTime(2026, 7, 24, 16),
              updatedAt: DateTime(2026, 7, 24, 16, 10),
            ),
            OperationalProcedure(
              id: 'device-delivery',
              name: 'Entrega do aparelho',
              description: 'Orientações de retirada e oferta de acessórios.',
              operationType: ProcedureOperationType.delivery,
              moment: ProcedureMoment.beforeDelivery,
              status: ProcedureStatus.active,
              required: false,
              stages: <ProcedureStage>[
                _stage(
                  id: 'device-delivery-check',
                  order: 1,
                  title: 'Conferência de entrega',
                  items: <ProcedureItem>[
                    _item(
                      'device-delivery-device',
                      1,
                      'Aparelho foi entregue ao cliente?',
                      ProcedureResponseType.confirmation,
                    ),
                    _item(
                      'device-delivery-accessories',
                      2,
                      'Acessórios recebidos foram devolvidos?',
                      ProcedureResponseType.yesNo,
                    ),
                  ],
                ),
                _stage(
                  id: 'device-delivery-offer',
                  order: 2,
                  title: 'Oferta complementar',
                  items: <ProcedureItem>[
                    _item(
                      'device-delivery-film',
                      1,
                      'Oferecer película de proteção.',
                      ProcedureResponseType.instruction,
                      required: false,
                    ),
                    _item(
                      'device-delivery-warranty',
                      2,
                      'Orientar sobre garantia do serviço.',
                      ProcedureResponseType.confirmation,
                    ),
                  ],
                ),
              ],
              createdAt: DateTime(2026, 7, 25, 9),
              updatedAt: DateTime(2026, 7, 25, 9, 15),
            ),
            OperationalProcedure(
              id: 'sale-finish',
              name: 'Finalização de venda',
              description:
                  'Conferência de quantidades, descontos e complementares.',
              operationType: ProcedureOperationType.sale,
              moment: ProcedureMoment.beforeFinish,
              status: ProcedureStatus.inactive,
              required: false,
              stages: <ProcedureStage>[
                _stage(
                  id: 'sale-finish-review',
                  order: 1,
                  title: 'Revisão da venda',
                  items: <ProcedureItem>[
                    _item(
                      'sale-finish-quantities',
                      1,
                      'Quantidades foram conferidas?',
                      ProcedureResponseType.confirmation,
                    ),
                    _item(
                      'sale-finish-discounts',
                      2,
                      'Descontos foram revisados?',
                      ProcedureResponseType.yesNo,
                    ),
                  ],
                ),
                _stage(
                  id: 'sale-finish-offer',
                  order: 2,
                  title: 'Complementares',
                  items: <ProcedureItem>[
                    _item(
                      'sale-finish-complement',
                      1,
                      'Oferecer produto complementar.',
                      ProcedureResponseType.instruction,
                      required: false,
                    ),
                  ],
                ),
              ],
              createdAt: DateTime(2026, 7, 20, 14),
              updatedAt: DateTime(2026, 7, 20, 14, 5),
            ),
          ],
        );
    }
  }
}

ProcedureStage _stage({
  required String id,
  required int order,
  required String title,
  String description = '',
  required List<ProcedureItem> items,
}) {
  return ProcedureStage(
    id: id,
    title: title,
    description: description,
    order: order,
    items: items,
  );
}

ProcedureItem _item(
  String id,
  int order,
  String title,
  ProcedureResponseType responseType, {
  bool required = true,
}) {
  return ProcedureItem(
    id: id,
    title: title,
    guidance: '',
    responseType: responseType,
    required: required,
    order: order,
  );
}

class OperationalProcedureMockException implements Exception {
  const OperationalProcedureMockException();

  @override
  String toString() {
    return 'Não foi possível carregar os procedimentos demonstrativos.';
  }
}
