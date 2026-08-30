import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../data/models/atendimento_tecnico_models.dart';

class AtendimentoTecnicoFotoPayload {
  const AtendimentoTecnicoFotoPayload._();

  static const int maxFotos = 10;
  static const int maxBytesPorFoto = 1000000;

  static Future<AtendimentoTecnicoFotoInput> fromXFile(XFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const AtendimentoTecnicoFotoException('PHOTO_EMPTY');
    }
    if (bytes.length > maxBytesPorFoto) {
      throw const AtendimentoTecnicoFotoException('PHOTO_TOO_LARGE');
    }

    final String? mimeType = _resolveMime(file.mimeType, bytes);
    if (mimeType == null) {
      throw const AtendimentoTecnicoFotoException('PHOTO_FORMAT_UNSUPPORTED');
    }
    return AtendimentoTecnicoFotoInput(
      nomeArquivo:
          file.name.trim().isEmpty
              ? 'foto-servico.${mimeType == 'image/png' ? 'png' : 'jpg'}'
              : file.name.trim(),
      mimeType: mimeType,
      conteudoBase64: 'data:$mimeType;base64,${base64Encode(bytes)}',
      tamanhoBytes: bytes.length,
    );
  }

  static AtendimentoTecnicoFotoInput fromModel(
    AtendimentoTecnicoFotoModel foto,
  ) {
    final String mimeType =
        _mimeFromDataUrl(foto.conteudoDataUrl) ?? foto.mimeType;
    return AtendimentoTecnicoFotoInput(
      nomeArquivo:
          foto.nomeArquivo.trim().isEmpty
              ? 'foto-servico.${mimeType == 'image/png' ? 'png' : 'jpg'}'
              : foto.nomeArquivo.trim(),
      mimeType: mimeType,
      conteudoBase64: foto.conteudoDataUrl.trim(),
      tamanhoBytes: foto.tamanhoBytes,
      legenda: foto.legenda,
    );
  }

  static Uint8List previewBytes(AtendimentoTecnicoFotoInput foto) {
    final String value = foto.conteudoBase64;
    final int comma = value.indexOf(',');
    return base64Decode(comma >= 0 ? value.substring(comma + 1) : value);
  }

  static String? _resolveMime(String? provided, Uint8List bytes) {
    final String normalized = (provided ?? '').trim().toLowerCase();
    if ((normalized == 'image/jpeg' || normalized == 'image/jpg') &&
        _isJpeg(bytes)) {
      return 'image/jpeg';
    }
    if (normalized == 'image/png' && _isPng(bytes)) {
      return 'image/png';
    }
    if (_isJpeg(bytes)) return 'image/jpeg';
    if (_isPng(bytes)) return 'image/png';
    return null;
  }

  static String? _mimeFromDataUrl(String value) {
    final String normalized = value.trim();
    if (!normalized.startsWith('data:')) return null;
    final int separator = normalized.indexOf(',');
    final String header =
        separator >= 0 ? normalized.substring(0, separator) : normalized;
    final String mimeType = header.substring(5).split(';').first.trim();
    return mimeType.isEmpty ? null : mimeType.toLowerCase();
  }

  static bool _isJpeg(Uint8List bytes) {
    return bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff;
  }

  static bool _isPng(Uint8List bytes) {
    return bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a;
  }
}

class AtendimentoTecnicoFotoException implements Exception {
  const AtendimentoTecnicoFotoException(this.code);

  final String code;
}
