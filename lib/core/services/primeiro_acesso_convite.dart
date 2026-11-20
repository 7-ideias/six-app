import 'package:flutter/foundation.dart';
import '../../data/models/colaborador_convite_model.dart';
import 'colaborador_convite_web_service.dart';

enum EtapaConvite {
  carregar,
  enviar,
  codigo,
  senha,
  existente,
  entrar,
  aceito,
  criado,
}

class PrimeiroAcessoConvite extends ChangeNotifier {
  PrimeiroAcessoConvite(this.codigo, {ColaboradorConviteWebService? service})
    : _service = service ?? ColaboradorConviteWebService();
  final String codigo;
  final ColaboradorConviteWebService _service;
  ColaboradorConvitePublicoResponse? convite;
  EtapaConvite etapa = EtapaConvite.carregar;
  bool ocupado = false;
  String? erro, _prova, email;
  bool _descartado = false;

  Future<void> carregar() => _executar(() async {
    convite = await _service.validarConvitePublico(codigo);
    etapa =
        convite!.contaExistente ? EtapaConvite.existente : EtapaConvite.enviar;
  });

  Future<void> enviar(String idioma) => _executar(() async {
    await _service.enviarCodigo(codigo, idioma);
    etapa = EtapaConvite.codigo;
  });

  Future<void> verificar(String otp) => _executar(() async {
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      throw const ConviteException('invalid');
    }
    final resultado = await _service.verificarCodigo(codigo, otp);
    _prova = resultado.prova;
    email = resultado.email;
    etapa = EtapaConvite.senha;
  });

  Future<void> salvar(String senha, String confirmar) => _executar(() async {
    if (senha.trim().isEmpty || senha.length < 8 || senha.length > 64) {
      throw const ConviteException('length');
    }
    if (senha != confirmar) throw const ConviteException('mismatch');
    await _service.criarSenha(codigo, _prova!, senha);
    _prova = null;
    etapa = EtapaConvite.criado;
  });

  Future<void> aceitar() => _executar(() async {
    await _service.aceitarConvite(codigo);
    etapa = EtapaConvite.aceito;
  });

  Future<void> _executar(Future<void> Function() operacao) async {
    if (ocupado || _descartado) return;
    ocupado = true;
    erro = null;
    notifyListeners();
    try {
      await operacao();
    } on ConviteException catch (e) {
      erro = e.key;
      if (e.key == 'wrongAccount' || e.key == 'signIn') {
        etapa = EtapaConvite.entrar;
      }
      if (e.key == 'verifyAgain') etapa = EtapaConvite.enviar;
    } catch (_) {
      erro = 'unavailable';
    } finally {
      ocupado = false;
      if (!_descartado) notifyListeners();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
