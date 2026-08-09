import 'dart:async';
import 'dart:ui';

import '../../../core/services/pdf_file_share_service.dart';
import '../../../data/services/atendimento_tecnico/atendimento_tecnico_api_client.dart';
import 'atendimento_tecnico_service.dart';

enum AtendimentoPdfShareFailure {
  notFound,
  permissionDenied,
  generationFailed,
  connectionFailed,
  timeout,
  invalidFile,
  shareUnavailable,
}

class AtendimentoPdfShareException implements Exception {
  const AtendimentoPdfShareException(this.failure, [this.cause]);

  final AtendimentoPdfShareFailure failure;
  final Object? cause;

  @override
  String toString() => 'AtendimentoPdfShareException($failure)';
}

class AtendimentoPdfShareResult {
  const AtendimentoPdfShareResult({
    required this.disposition,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });

  final PdfFileShareDisposition disposition;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
}

class AtendimentoPdfShareService {
  AtendimentoPdfShareService({
    AtendimentoTecnicoService? atendimentoService,
    PdfFileShareService? fileShareService,
  }) : _atendimentoService = atendimentoService ?? AtendimentoTecnicoService(),
       _fileShareService = fileShareService ?? const PdfFileShareService();

  final AtendimentoTecnicoService _atendimentoService;
  final PdfFileShareService _fileShareService;

  Future<AtendimentoPdfShareResult> compartilharAtendimento({
    required String atendimentoId,
    Rect? sharePositionOrigin,
  }) async {
    try {
      final pdf = await _atendimentoService.gerarPdf(id: atendimentoId);
      final result = await _fileShareService.sharePdfResponse(
        pdf,
        sharePositionOrigin: sharePositionOrigin,
      );
      return AtendimentoPdfShareResult(
        disposition: result.disposition,
        fileName: result.fileName,
        mimeType: result.mimeType,
        sizeBytes: result.sizeBytes,
      );
    } on AtendimentoTecnicoApiException catch (error) {
      throw AtendimentoPdfShareException(
        _failureFromStatus(error.statusCode),
        error,
      );
    } on TimeoutException catch (error) {
      throw AtendimentoPdfShareException(
        AtendimentoPdfShareFailure.timeout,
        error,
      );
    } on PdfFileShareException catch (error) {
      throw AtendimentoPdfShareException(_failureFromFileError(error), error);
    } catch (error) {
      throw AtendimentoPdfShareException(
        AtendimentoPdfShareFailure.generationFailed,
        error,
      );
    }
  }

  AtendimentoPdfShareFailure _failureFromStatus(int statusCode) {
    if (statusCode == 403) {
      return AtendimentoPdfShareFailure.permissionDenied;
    }
    if (statusCode == 404) {
      return AtendimentoPdfShareFailure.notFound;
    }
    if (statusCode == 0 || statusCode == 408 || statusCode == 504) {
      return AtendimentoPdfShareFailure.connectionFailed;
    }
    return AtendimentoPdfShareFailure.generationFailed;
  }

  AtendimentoPdfShareFailure _failureFromFileError(
    PdfFileShareException error,
  ) {
    if (error.failure == PdfFileShareFailure.shareUnavailable) {
      return AtendimentoPdfShareFailure.shareUnavailable;
    }
    return AtendimentoPdfShareFailure.invalidFile;
  }
}
