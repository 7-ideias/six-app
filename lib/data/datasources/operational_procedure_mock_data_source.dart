import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/data/datasources/operational_procedure_data_source.dart';

enum OperationalProcedureMockScenario { success, empty, error }

enum OperationalProcedureRuntimeMockScenario {
  none,
  informative,
  recommended,
  required,
  multiple,
}

class OperationalProcedureMockDataSource
    implements OperationalProcedureDataSource {
  const OperationalProcedureMockDataSource({
    this.scenario = OperationalProcedureMockScenario.success,
    this.runtimeScenario = OperationalProcedureRuntimeMockScenario.none,
    this.delay = const Duration(milliseconds: 520),
  });

  final OperationalProcedureMockScenario scenario;
  final OperationalProcedureRuntimeMockScenario runtimeScenario;
  final Duration delay;

  @override
  Future<OperationalProcedureSummary> fetchProcedures({
    String idioma = 'pt-BR',
    bool somenteAtivos = false,
  }) async {
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
              triggers: <ProcedureTrigger>[
                _trigger(
                  id: 'device-intake-trigger-open',
                  order: 1,
                  operationType: ProcedureOperationType.technicalService,
                  triggerMoment: ProcedureTriggerMoment.beforeStart,
                  activationMode: ProcedureTriggerActivationMode.automatic,
                  enforcementMode: ProcedureEnforcementMode.required,
                ),
                _trigger(
                  id: 'device-intake-trigger-close',
                  order: 2,
                  operationType: ProcedureOperationType.technicalService,
                  triggerMoment: ProcedureTriggerMoment.beforeFinish,
                  activationMode: ProcedureTriggerActivationMode.manual,
                  enforcementMode: ProcedureEnforcementMode.recommended,
                ),
              ],
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
              triggers: <ProcedureTrigger>[
                _trigger(
                  id: 'service-closing-trigger',
                  order: 1,
                  operationType: ProcedureOperationType.technicalService,
                  triggerMoment: ProcedureTriggerMoment.beforeFinish,
                  activationMode: ProcedureTriggerActivationMode.automatic,
                  enforcementMode: ProcedureEnforcementMode.required,
                ),
              ],
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
              triggers: <ProcedureTrigger>[
                _trigger(
                  id: 'device-delivery-warranty-trigger',
                  order: 1,
                  operationType: ProcedureOperationType.delivery,
                  triggerMoment: ProcedureTriggerMoment.beforeDelivery,
                  activationMode: ProcedureTriggerActivationMode.manual,
                  enforcementMode: ProcedureEnforcementMode.informative,
                  enabled: false,
                ),
              ],
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
              id: 'complete-device-intake',
              name: 'Recepção completa de aparelho',
              description:
                  'Demonstração com identificação, evidências e aceite do cliente.',
              operationType: ProcedureOperationType.technicalService,
              moment: ProcedureMoment.beforeStart,
              status: ProcedureStatus.active,
              required: true,
              triggers: <ProcedureTrigger>[
                _trigger(
                  id: 'complete-device-trigger-open',
                  order: 1,
                  operationType: ProcedureOperationType.technicalService,
                  triggerMoment: ProcedureTriggerMoment.beforeStart,
                  activationMode: ProcedureTriggerActivationMode.automatic,
                  enforcementMode: ProcedureEnforcementMode.required,
                ),
                _trigger(
                  id: 'complete-device-trigger-delivery',
                  order: 2,
                  operationType: ProcedureOperationType.delivery,
                  triggerMoment: ProcedureTriggerMoment.beforeDelivery,
                  activationMode: ProcedureTriggerActivationMode.automatic,
                  enforcementMode: ProcedureEnforcementMode.recommended,
                ),
              ],
              stages: <ProcedureStage>[
                _stage(
                  id: 'complete-device-identification',
                  order: 1,
                  title: 'Identificação',
                  items: <ProcedureItem>[
                    _item(
                      'complete-device-chip',
                      1,
                      'O aparelho possui chip?',
                      ProcedureResponseType.yesNo,
                    ),
                    _item(
                      'complete-device-imei',
                      2,
                      'Informe o IMEI.',
                      ProcedureResponseType.imei,
                    ),
                    _item(
                      'complete-device-barcode',
                      3,
                      'Leia o código de barras da etiqueta.',
                      ProcedureResponseType.barcode,
                    ),
                  ],
                ),
                _stage(
                  id: 'complete-device-condition',
                  order: 2,
                  title: 'Condição do aparelho',
                  items: <ProcedureItem>[
                    _item(
                      'complete-device-damage-notes',
                      1,
                      'Registre as avarias visíveis.',
                      ProcedureResponseType.freeText,
                      configuration: const ProcedureItemConfiguration(
                        placeholder: 'Ex.: tela trincada, riscos na lateral',
                      ),
                    ),
                    _item(
                      'complete-device-photo',
                      2,
                      'Tire uma foto do aparelho.',
                      ProcedureResponseType.photo,
                    ),
                    _item(
                      'complete-device-accessories',
                      3,
                      'Confirme que os acessórios foram registrados.',
                      ProcedureResponseType.confirmation,
                    ),
                  ],
                ),
                _stage(
                  id: 'complete-device-acceptance',
                  order: 3,
                  title: 'Aceite',
                  items: <ProcedureItem>[
                    _item(
                      'complete-device-deadline',
                      1,
                      'Oriente o cliente sobre o prazo.',
                      ProcedureResponseType.instruction,
                    ),
                    _item(
                      'complete-device-signature',
                      2,
                      'Colete a assinatura.',
                      ProcedureResponseType.signature,
                    ),
                  ],
                ),
              ],
              createdAt: DateTime(2026, 7, 26, 11),
              updatedAt: DateTime(2026, 7, 26, 11, 20),
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
              triggers: <ProcedureTrigger>[
                _trigger(
                  id: 'sale-finish-parking-trigger',
                  order: 1,
                  operationType: ProcedureOperationType.sale,
                  triggerMoment: ProcedureTriggerMoment.beforeFinish,
                  activationMode: ProcedureTriggerActivationMode.automatic,
                  enforcementMode: ProcedureEnforcementMode.required,
                ),
                _trigger(
                  id: 'sale-finish-cash-trigger',
                  order: 2,
                  operationType: ProcedureOperationType.cashRegister,
                  triggerMoment: ProcedureTriggerMoment.beforeFinish,
                  activationMode: ProcedureTriggerActivationMode.automatic,
                  enforcementMode: ProcedureEnforcementMode.recommended,
                ),
              ],
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
            OperationalProcedure(
              id: 'parking-validation',
              name: 'Validação de estacionamento',
              description:
                  'Conferência demonstrativa antes de concluir uma venda.',
              operationType: ProcedureOperationType.sale,
              moment: ProcedureMoment.beforeFinish,
              status: ProcedureStatus.active,
              required: true,
              triggers: <ProcedureTrigger>[
                _trigger(
                  id: 'parking-validation-trigger',
                  order: 1,
                  operationType: ProcedureOperationType.sale,
                  triggerMoment: ProcedureTriggerMoment.beforeFinish,
                  activationMode: ProcedureTriggerActivationMode.automatic,
                  enforcementMode: ProcedureEnforcementMode.required,
                ),
              ],
              stages: <ProcedureStage>[
                _stage(
                  id: 'parking-validation-stage',
                  order: 1,
                  title: 'Conferência',
                  items: <ProcedureItem>[
                    _item(
                      'parking-validation-ticket',
                      1,
                      'Estacionamento foi validado para o cliente?',
                      ProcedureResponseType.confirmation,
                    ),
                  ],
                ),
              ],
              createdAt: DateTime(2026, 7, 29, 12),
              updatedAt: DateTime(2026, 7, 29, 12, 5),
            ),
            OperationalProcedure(
              id: 'cash-closing-checklist',
              name: 'Checklist de fechamento',
              description: 'Conferência demonstrativa antes de fechar o caixa.',
              operationType: ProcedureOperationType.cashRegister,
              moment: ProcedureMoment.beforeFinish,
              status: ProcedureStatus.active,
              required: false,
              triggers: <ProcedureTrigger>[
                _trigger(
                  id: 'cash-closing-trigger',
                  order: 1,
                  operationType: ProcedureOperationType.cashRegister,
                  triggerMoment: ProcedureTriggerMoment.beforeFinish,
                  activationMode: ProcedureTriggerActivationMode.automatic,
                  enforcementMode: ProcedureEnforcementMode.recommended,
                ),
              ],
              stages: <ProcedureStage>[
                _stage(
                  id: 'cash-closing-stage',
                  order: 1,
                  title: 'Fechamento',
                  items: <ProcedureItem>[
                    _item(
                      'cash-closing-values',
                      1,
                      'Valores do caixa foram conferidos?',
                      ProcedureResponseType.confirmation,
                    ),
                    _item(
                      'cash-closing-notes',
                      2,
                      'Registre observações do fechamento.',
                      ProcedureResponseType.freeText,
                      required: false,
                    ),
                  ],
                ),
              ],
              createdAt: DateTime(2026, 7, 29, 13),
              updatedAt: DateTime(2026, 7, 29, 13, 5),
            ),
            ..._runtimeProcedures(runtimeScenario),
          ],
        );
    }
  }

  @override
  Future<OperationalProcedure> saveProcedure({
    required OperationalProcedure procedure,
    required String idioma,
    required bool isCreating,
  }) async {
    await Future<void>.delayed(delay);
    if (scenario == OperationalProcedureMockScenario.error) {
      throw const OperationalProcedureMockException();
    }
    return procedure;
  }
}

ProcedureTrigger _trigger({
  required String id,
  required int order,
  required ProcedureOperationType operationType,
  required ProcedureTriggerMoment triggerMoment,
  required ProcedureTriggerActivationMode activationMode,
  required ProcedureEnforcementMode enforcementMode,
  bool enabled = true,
  ProcedureOperationPoint? operationPoint,
}) {
  return ProcedureTrigger(
    id: id,
    operationPoint: operationPoint,
    operationType: operationType,
    triggerMoment: triggerMoment,
    activationMode: activationMode,
    enforcementMode: enforcementMode,
    enabled: enabled,
    order: order,
    createdAt: DateTime(2026, 7, 29, 9),
    updatedAt: DateTime(2026, 7, 29, 9, 5),
  );
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
  List<String> options = const <String>[],
  ProcedureItemConfiguration configuration = const ProcedureItemConfiguration(),
}) {
  return ProcedureItem(
    id: id,
    title: title,
    guidance: '',
    responseType: responseType,
    required: required,
    order: order,
    options: options,
    configuration: configuration,
  );
}

List<OperationalProcedure> _runtimeProcedures(
  OperationalProcedureRuntimeMockScenario scenario,
) {
  return switch (scenario) {
    OperationalProcedureRuntimeMockScenario.none =>
      const <OperationalProcedure>[],
    OperationalProcedureRuntimeMockScenario.informative =>
      <OperationalProcedure>[
        _saleStartProcedure(
          id: 'sale-start-informative',
          name: 'Orientação para início da venda',
          description:
              'Lembretes rápidos antes de abrir o atendimento no caixa.',
          enforcementMode: ProcedureEnforcementMode.informative,
          items: <ProcedureItem>[
            _item(
              'sale-start-info-read',
              1,
              'Cumprimente o cliente e confirme se precisa de ajuda.',
              ProcedureResponseType.instruction,
              required: false,
            ),
          ],
        ),
      ],
    OperationalProcedureRuntimeMockScenario.recommended =>
      <OperationalProcedure>[
        _saleStartProcedure(
          id: 'sale-start-recommended',
          name: 'Conferência rápida antes da venda',
          description: 'Valide pontos básicos antes de iniciar a venda.',
          enforcementMode: ProcedureEnforcementMode.recommended,
          items: <ProcedureItem>[
            _item(
              'sale-start-recommended-confirm',
              1,
              'O cliente encontrou o que precisava?',
              ProcedureResponseType.yesNo,
              required: true,
            ),
          ],
        ),
      ],
    OperationalProcedureRuntimeMockScenario.required => <OperationalProcedure>[
      _saleStartProcedure(
        id: 'sale-start-required-parking',
        name: 'Validação de estacionamento',
        description: 'Confirmação obrigatória antes de iniciar a venda.',
        enforcementMode: ProcedureEnforcementMode.required,
        items: <ProcedureItem>[
          _item(
            'sale-start-parking-question',
            1,
            'O cliente precisa validar o estacionamento?',
            ProcedureResponseType.yesNo,
            required: true,
          ),
          _item(
            'sale-start-found-everything',
            2,
            'O cliente encontrou tudo o que precisava?',
            ProcedureResponseType.yesNo,
            required: true,
            configuration: const ProcedureItemConfiguration(
              requireTextWhenNo: true,
              negativeTextPlaceholder:
                  'Descreva o que o cliente ainda procura.',
            ),
          ),
        ],
      ),
    ],
    OperationalProcedureRuntimeMockScenario.multiple => <OperationalProcedure>[
      ..._runtimeProcedures(OperationalProcedureRuntimeMockScenario.required),
      ..._runtimeProcedures(
        OperationalProcedureRuntimeMockScenario.recommended,
      ),
      ..._runtimeProcedures(
        OperationalProcedureRuntimeMockScenario.informative,
      ),
    ],
  };
}

OperationalProcedure _saleStartProcedure({
  required String id,
  required String name,
  required String description,
  required ProcedureEnforcementMode enforcementMode,
  required List<ProcedureItem> items,
}) {
  return OperationalProcedure(
    id: id,
    name: name,
    description: description,
    operationType: ProcedureOperationType.sale,
    moment: ProcedureMoment.beforeStart,
    status: ProcedureStatus.active,
    required: enforcementMode == ProcedureEnforcementMode.required,
    triggers: <ProcedureTrigger>[
      _trigger(
        id: '$id-trigger',
        order: 1,
        operationPoint: ProcedureOperationPoint.saleStartBefore,
        operationType: ProcedureOperationType.sale,
        triggerMoment: ProcedureTriggerMoment.beforeStart,
        activationMode: ProcedureTriggerActivationMode.automatic,
        enforcementMode: enforcementMode,
      ),
    ],
    stages: <ProcedureStage>[
      _stage(
        id: '$id-stage',
        order: 1,
        title: 'Antes de iniciar a venda',
        items: items,
      ),
    ],
    createdAt: DateTime(2026, 7, 29, 15),
    updatedAt: DateTime(2026, 7, 29, 15, 5),
  );
}

class OperationalProcedureMockException implements Exception {
  const OperationalProcedureMockException();

  @override
  String toString() {
    return 'Não foi possível carregar os procedimentos demonstrativos.';
  }
}
