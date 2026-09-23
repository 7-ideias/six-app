import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/services/admin_portal_service.dart';
import '../data/models/agenda_email_models.dart';

/// Shared request state only. Each platform owns its dialog/sheet composition.
class AgendaEmailReenvioController extends ChangeNotifier {
  AgendaEmailReenvioController(this.service, this.idUsuario);
  final AdminPortalService service;
  final String idUsuario;
  List<AgendaEmailDestino> destinos = [];
  AgendaEmailDestino? selecionado;
  bool carregando = true;
  bool enviando = false;
  bool _disposed = false;
  String? mensagem;
  AgendaEmailResultado? resultado;
  final Map<String, String> _chaves = {};

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> carregar() async {
    carregando = true;
    mensagem = null;
    _notify();
    try {
      destinos = await service.listarDestinosAgendaEmail(idUsuario);
      selecionado = destinos.length == 1 ? destinos.single : null;
    } catch (e) {
      mensagem = _erro(e);
    }
    carregando = false;
    _notify();
  }

  void selecionar(AgendaEmailDestino destino) {
    if (enviando || resultado != null) return;
    selecionado = destino;
    mensagem = null;
    _notify();
  }

  Future<void> enviar() async {
    final destino = selecionado;
    if (enviando || destino == null || resultado != null) return;
    enviando = true;
    mensagem = null;
    _notify();
    // Keep the same key after a network failure: an accepted message must not be resent.
    final chave = _chaves.putIfAbsent(destino.idEmpresa, _uuid);
    try {
      resultado = await service.reenviarAgendaEmail(
        idUsuario: idUsuario,
        idEmpresa: destino.idEmpresa,
        chaveRequisicao: chave,
      );
      mensagem = switch (resultado!.status) {
        'ENVIADO' => 'success',
        'PREPARANDO' || 'ENVIANDO' => 'processingRecorded',
        'INCERTO' => 'uncertain',
        'CANCELADO' => 'cancelled',
        'FALHOU' => 'failed',
        _ => 'uncertain',
      };
    } catch (e) {
      mensagem = _erro(e);
    }
    enviando = false;
    _notify();
  }

  static String _erro(Object e) =>
      e is AgendaEmailException
          ? switch (e.codigo) {
            'PERMISSAO_NEGADA' => 'forbidden',
            'AGENDA_EMAIL_DESABILITADO' => 'disabled',
            'DESTINATARIO_NAO_ELEGIVEL' => 'ineligible',
            'REENVIO_EM_ANDAMENTO' || 'REENVIO_AGUARDE' => 'cooldown',
            _ => 'error',
          }
          : 'error';

  static String _uuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
