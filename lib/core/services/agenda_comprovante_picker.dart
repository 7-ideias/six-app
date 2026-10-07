import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:sixpos/data/models/agenda_imposto_renda.dart';

class AgendaComprovantePicker {
  Future<AgendaComprovanteIr?> selecionar({bool camera = false}) async {
    final arquivo = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (arquivo == null) return null;
    if (await arquivo.length() > 2 * 1024 * 1024)
      throw const FormatException('IR_COMPROVANTE_INVALIDO');
    final bytes = await arquivo.readAsBytes();
    if (!AgendaComprovanteIr.imagemValida(bytes))
      throw const FormatException('IR_COMPROVANTE_INVALIDO');
    final nome =
        arquivo.name.trim().isEmpty ? 'comprovante.jpg' : arquivo.name.trim();
    return AgendaComprovanteIr(
      nome: nome.length > 120 ? nome.substring(0, 120) : nome,
      conteudoBase64: base64Encode(bytes),
    );
  }
}
