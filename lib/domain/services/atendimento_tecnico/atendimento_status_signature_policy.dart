import '../../../data/models/atendimento_tecnico_models.dart';
import '../../../data/models/dominio_models.dart';

class AtendimentoStatusSignaturePolicy {
  const AtendimentoStatusSignaturePolicy._();

  static const Set<String> _restrictedStatusCodes = <String>{
    'QUOTE_SENT',
    'ORCAMENTO_ENVIADO',
    'ORÇAMENTO_ENVIADO',
    'SENT',
    'WAITING_CUSTOMER_APROVAL',
    'WAITING_CUSTOMER_APPROVAL',
    'AGUARDANDO_APROVACAO',
    'AGUARDANDO_APROVAÇÃO',
    'AGUARDANDO_APROVACAO_CLIENTE',
    'AGUARDANDO_APROVAÇÃO_CLIENTE',
    'IN_PROGRESS',
    'EM_EXECUCAO',
    'EM_EXECUÇÃO',
    'EXECUCAO',
    'EXECUÇÃO',
    'EM_ANDAMENTO',
  };

  static bool statusExigeAssinatura(DominioOpcaoModel? status) {
    if (status == null) return false;
    final String code = status.codigo.trim().toUpperCase();
    if (_restrictedStatusCodes.contains(code)) return true;

    final String source = _normalize(
      <String>[
        status.codigo,
        status.i18nKey,
        status.nomePadraoPtBr,
        status.nomePadraoEnUs,
        status.nomePadraoEsEs,
      ].join(' '),
    );
    return source.contains('ORCAMENTOENVIADO') ||
        source.contains('QUOTESENT') ||
        source.contains('AGUARDANDOAPROVACAODOCLIENTE') ||
        source.contains('WAITINGCUSTOMERAPROVAL') ||
        source.contains('WAITINGCUSTOMERAPPROVAL') ||
        source.contains('EMEXECUCAO') ||
        source.contains('INPROGRESS');
  }

  static bool atendimentoPrecisaAssinaturaPara({
    required AtendimentoTecnicoModel atendimento,
    required DominioOpcaoModel? status,
  }) {
    if (!statusExigeAssinatura(status)) return false;
    return !atendimento.assinaturaAprovada || atendimento.requerNovaAssinatura;
  }

  static String _normalize(String value) {
    return value
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('À', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('Ã', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ô', 'O')
        .replaceAll('Õ', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ç', 'C')
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }
}
