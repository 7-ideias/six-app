import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/services/agenda_venda_comprovante_service.dart';
import 'package:sixpos/core/services/pdf_file_share_service.dart';
import 'package:sixpos/data/models/documento_models.dart';
import 'package:sixpos/data/models/operacao_models.dart';
import 'package:sixpos/data/services/operacao/operacao_api_client.dart';

class _OperacoesFake implements OperacaoApiClient {
  String? ultimaOperacao;
  FormatoImpressaoOperacao? ultimoFormato;
  @override
  Future<OperacaoInserirResponse> inserirOperacao({
    required OperacaoInserirRequest request,
  }) async => throw UnimplementedError();

  @override
  Future<DocumentoPdfResponse> imprimirComprovanteOperacao({
    required String idOperacao,
    required FormatoImpressaoOperacao formato,
  }) async {
    ultimaOperacao = idOperacao;
    ultimoFormato = formato;
    final pdf = Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 52]);
    return DocumentoPdfResponse(
      arquivoBase64: base64Encode(pdf),
      nomeArquivo: 'venda.pdf',
      mimeType: 'application/pdf',
      tamanhoBytes: pdf.length,
    );
  }
}

class _ShareFake implements PdfFileShareAdapter {
  String? nome;
  @override
  Future<PdfFileShareResult> sharePdf({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    Rect? sharePositionOrigin,
  }) async {
    nome = fileName;
    return PdfFileShareResult(
      disposition: PdfFileShareDisposition.shared,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: bytes.length,
    );
  }
}

void main() {
  test('comprovante usa id original e formato de cupom termico', () async {
    final api = _OperacoesFake();
    final service = AgendaVendaComprovanteService(operacoes: api);
    final pdf = await service.gerar(
      'id-original',
      formato: FormatoImpressaoOperacao.cupomTermico,
    );
    expect(api.ultimaOperacao, 'id-original');
    expect(api.ultimoFormato, FormatoImpressaoOperacao.cupomTermico);
    expect(pdf.mimeType, 'application/pdf');
  });

  test('compartilhamento reaproveita adaptador nativo existente', () async {
    final api = _OperacoesFake();
    final share = _ShareFake();
    final service = AgendaVendaComprovanteService(
      operacoes: api,
      compartilhar: PdfFileShareService(adapter: share),
    );
    final pdf = await service.gerar('id-original');
    final resultado = await service.compartilharMobile(pdf);
    expect(resultado.disposition, PdfFileShareDisposition.shared);
    expect(share.nome, 'venda.pdf');
  });

  test('venda sem id original nao tenta gerar comprovante', () async {
    final service = AgendaVendaComprovanteService(operacoes: _OperacoesFake());
    await expectLater(service.gerar('   '), throwsStateError);
  });
}
