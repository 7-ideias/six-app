import 'package:flutter/material.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/l10n/six_i18n.dart';

enum ProcedureResponseTypeCategory {
  guide,
  collectInformation,
  evidence,
  identify,
}

class ProcedureResponseTypeMetadata {
  const ProcedureResponseTypeMetadata({
    required this.type,
    required this.category,
    required this.icon,
    this.acceptsOptions = false,
    this.acceptsPlaceholder = false,
    this.acceptsUnit = false,
    this.simulated = false,
    this.allowsRequired = true,
  });

  final ProcedureResponseType type;
  final ProcedureResponseTypeCategory category;
  final IconData icon;
  final bool acceptsOptions;
  final bool acceptsPlaceholder;
  final bool acceptsUnit;
  final bool simulated;
  final bool allowsRequired;
}

const List<ProcedureResponseTypeMetadata> procedureResponseTypeMetadata =
    <ProcedureResponseTypeMetadata>[
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.instruction,
        category: ProcedureResponseTypeCategory.guide,
        icon: Icons.info_outline_rounded,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.confirmation,
        category: ProcedureResponseTypeCategory.guide,
        icon: Icons.task_alt_rounded,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.yesNo,
        category: ProcedureResponseTypeCategory.guide,
        icon: Icons.help_outline_rounded,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.freeText,
        category: ProcedureResponseTypeCategory.collectInformation,
        icon: Icons.notes_rounded,
        acceptsPlaceholder: true,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.number,
        category: ProcedureResponseTypeCategory.collectInformation,
        icon: Icons.pin_rounded,
        acceptsPlaceholder: true,
        acceptsUnit: true,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.date,
        category: ProcedureResponseTypeCategory.collectInformation,
        icon: Icons.calendar_today_rounded,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.singleChoice,
        category: ProcedureResponseTypeCategory.collectInformation,
        icon: Icons.radio_button_checked_rounded,
        acceptsOptions: true,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.multipleChoice,
        category: ProcedureResponseTypeCategory.collectInformation,
        icon: Icons.checklist_rounded,
        acceptsOptions: true,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.photo,
        category: ProcedureResponseTypeCategory.evidence,
        icon: Icons.photo_camera_outlined,
        simulated: true,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.signature,
        category: ProcedureResponseTypeCategory.evidence,
        icon: Icons.draw_outlined,
        simulated: true,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.location,
        category: ProcedureResponseTypeCategory.evidence,
        icon: Icons.location_on_outlined,
        simulated: true,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.document,
        category: ProcedureResponseTypeCategory.evidence,
        icon: Icons.attach_file_rounded,
        simulated: true,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.audio,
        category: ProcedureResponseTypeCategory.evidence,
        icon: Icons.mic_none_rounded,
        simulated: true,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.barcode,
        category: ProcedureResponseTypeCategory.identify,
        icon: Icons.qr_code_scanner_rounded,
        simulated: true,
      ),
      ProcedureResponseTypeMetadata(
        type: ProcedureResponseType.imei,
        category: ProcedureResponseTypeCategory.identify,
        icon: Icons.numbers_rounded,
      ),
    ];

ProcedureResponseTypeMetadata metadataForResponseType(
  ProcedureResponseType type,
) {
  return procedureResponseTypeMetadata.firstWhere(
    (ProcedureResponseTypeMetadata metadata) => metadata.type == type,
  );
}

IconData responseTypeIcon(ProcedureResponseType type) {
  return metadataForResponseType(type).icon;
}

String responseTypeLabel(BuildContext context, ProcedureResponseType type) {
  return switch (type) {
    ProcedureResponseType.instruction => context.t(
      'procedimentos.responseInstruction',
      fallback: 'Orientação',
    ),
    ProcedureResponseType.confirmation => context.t(
      'procedimentos.responseConfirmation',
      fallback: 'Confirmação',
    ),
    ProcedureResponseType.yesNo => context.t(
      'procedimentos.responseYesNo',
      fallback: 'Sim ou não',
    ),
    ProcedureResponseType.photo => context.t(
      'procedimentos.responsePhoto',
      fallback: 'Tirar foto',
    ),
    ProcedureResponseType.signature => context.t(
      'procedimentos.responseSignature',
      fallback: 'Assinatura',
    ),
    ProcedureResponseType.location => context.t(
      'procedimentos.responseLocation',
      fallback: 'Capturar localização',
    ),
    ProcedureResponseType.barcode => context.t(
      'procedimentos.responseBarcode',
      fallback: 'Ler código de barras',
    ),
    ProcedureResponseType.imei => context.t(
      'procedimentos.responseImei',
      fallback: 'Informar IMEI',
    ),
    ProcedureResponseType.document => context.t(
      'procedimentos.responseDocument',
      fallback: 'Anexar documento',
    ),
    ProcedureResponseType.audio => context.t(
      'procedimentos.responseAudio',
      fallback: 'Gravar áudio',
    ),
    ProcedureResponseType.freeText => context.t(
      'procedimentos.responseFreeText',
      fallback: 'Texto livre',
    ),
    ProcedureResponseType.number => context.t(
      'procedimentos.responseNumber',
      fallback: 'Número',
    ),
    ProcedureResponseType.date => context.t(
      'procedimentos.responseDate',
      fallback: 'Data',
    ),
    ProcedureResponseType.singleChoice => context.t(
      'procedimentos.responseSingleChoice',
      fallback: 'Escolha única',
    ),
    ProcedureResponseType.multipleChoice => context.t(
      'procedimentos.responseMultipleChoice',
      fallback: 'Escolha múltipla',
    ),
  };
}

String responseTypeDescription(
  BuildContext context,
  ProcedureResponseType type,
) {
  return switch (type) {
    ProcedureResponseType.instruction => context.t(
      'procedimentos.responseInstructionDescription',
      fallback: 'Apresenta uma instrução ao colaborador.',
    ),
    ProcedureResponseType.confirmation => context.t(
      'procedimentos.responseConfirmationDescription',
      fallback: 'Exige que o colaborador confirme uma ação.',
    ),
    ProcedureResponseType.yesNo => context.t(
      'procedimentos.responseYesNoDescription',
      fallback: 'Apresenta uma pergunta objetiva.',
    ),
    ProcedureResponseType.photo => context.t(
      'procedimentos.responsePhotoDescription',
      fallback: 'Simula a captura de uma foto como evidência.',
    ),
    ProcedureResponseType.signature => context.t(
      'procedimentos.responseSignatureDescription',
      fallback: 'Simula a coleta de uma assinatura.',
    ),
    ProcedureResponseType.location => context.t(
      'procedimentos.responseLocationDescription',
      fallback: 'Simula a captura de uma localização.',
    ),
    ProcedureResponseType.barcode => context.t(
      'procedimentos.responseBarcodeDescription',
      fallback: 'Simula a leitura de um código de barras.',
    ),
    ProcedureResponseType.imei => context.t(
      'procedimentos.responseImeiDescription',
      fallback: 'Permite informar um IMEI manualmente.',
    ),
    ProcedureResponseType.document => context.t(
      'procedimentos.responseDocumentDescription',
      fallback: 'Simula o anexo de um documento.',
    ),
    ProcedureResponseType.audio => context.t(
      'procedimentos.responseAudioDescription',
      fallback: 'Simula uma gravação de áudio.',
    ),
    ProcedureResponseType.freeText => context.t(
      'procedimentos.responseFreeTextDescription',
      fallback: 'Permite registrar uma resposta em texto.',
    ),
    ProcedureResponseType.number => context.t(
      'procedimentos.responseNumberDescription',
      fallback: 'Permite registrar um valor numérico.',
    ),
    ProcedureResponseType.date => context.t(
      'procedimentos.responseDateDescription',
      fallback: 'Permite selecionar uma data.',
    ),
    ProcedureResponseType.singleChoice => context.t(
      'procedimentos.responseSingleChoiceDescription',
      fallback: 'Permite selecionar uma opção.',
    ),
    ProcedureResponseType.multipleChoice => context.t(
      'procedimentos.responseMultipleChoiceDescription',
      fallback: 'Permite selecionar uma ou mais opções.',
    ),
  };
}

String responseTypeCategoryLabel(
  BuildContext context,
  ProcedureResponseTypeCategory category,
) {
  return switch (category) {
    ProcedureResponseTypeCategory.guide => context.t(
      'procedimentos.typeCategoryGuide',
      fallback: 'Orientar e confirmar',
    ),
    ProcedureResponseTypeCategory.collectInformation => context.t(
      'procedimentos.typeCategoryCollect',
      fallback: 'Coletar informação',
    ),
    ProcedureResponseTypeCategory.evidence => context.t(
      'procedimentos.typeCategoryEvidence',
      fallback: 'Registrar evidência',
    ),
    ProcedureResponseTypeCategory.identify => context.t(
      'procedimentos.typeCategoryIdentify',
      fallback: 'Identificar',
    ),
  };
}

bool isChoiceResponseType(ProcedureResponseType type) {
  return type == ProcedureResponseType.singleChoice ||
      type == ProcedureResponseType.multipleChoice;
}

bool isSimulatedResponseType(ProcedureResponseType type) {
  return metadataForResponseType(type).simulated;
}
