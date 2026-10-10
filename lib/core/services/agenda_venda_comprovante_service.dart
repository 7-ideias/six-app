import 'dart:convert';
import 'dart:ui';

import 'package:sixpos/core/services/pdf_file_share_service.dart';
import 'package:sixpos/core/utils/pdf_download.dart';
import 'package:sixpos/data/models/atendimento_tecnico_models.dart';
import 'package:sixpos/data/models/documento_models.dart';
import 'package:sixpos/data/models/operacao_models.dart';
import 'package:sixpos/data/services/operacao/operacao_api_client.dart';

/// Reaproveita o comprovante original de venda e a folha nativa de compartilhamento.
class AgendaVendaComprovanteService {
  AgendaVendaComprovanteService({
    OperacaoApiClient? operacoes,
    PdfFileShareService? compartilhar,
  })  : _operacoes = operacoes ?? HttpOperacaoApiClient(),
        _compartilhar = compartilhar ?? const PdfFileShareService();

  final OperacaoApiClient _operacoes;
  final PdfFileShareService _compartilhar;

  Future<DocumentoPdfResponse> gerar(
    String idOperacao, {
    FormatoImpressaoOperacao formato = FormatoImpressaoOperacao.a4,
  }) {
    if (idOperacao.trim().isEmpty) {
      throw StateError('Operação de venda não disponível para comprovante.');
    }
    return _operacoes.imprimirComprovanteOperacao(
      idOperacao: idOperacao,
      formato: formato,
    );
  }

  bool baixarWeb(DocumentoPdfResponse pdf) {
    if (pdf.mimeType.toLowerCase() != 'application/pdf') {
      throw const FormatException('Tipo de documento inválido.');
    }
    final bytes = base64Decode(pdf.arquivoBase64);
    if (!_ehPdf(bytes)) throw const FormatException('Comprovante PDF inválido.');
    return iniciarDownloadPdf(
      bytes: bytes,
      nomeArquivo: pdf.nomeArquivo,
      mimeType: pdf.mimeType,
    );
  }

  Future<PdfFileShareResult> compartilharMobile(
    DocumentoPdfResponse pdf, {
    Rect? posicaoDeOrigem,
  }) => _compartilhar.sharePdfResponse(
    AtendimentoTecnicoPdfResponseModel(
      fileName: pdf.nomeArquivo,
      mimeType: pdf.mimeType,
      base64: pdf.arquivoBase64,
      sizeBytes: pdf.tamanhoBytes,
      generatedAt: pdf.geradoEm,
    ),
    sharePositionOrigin: posicaoDeOrigem,
  );

  static bool _ehPdf(List<int> bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46;
}
