import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sixpos/data/models/usuario_model.dart';
import 'package:sixpos/domain/services/usuario/usuario_service.dart';
import 'package:sixpos/providers/usuario_provider.dart';

typedef MobileCardOrderSelector<T extends Object> =
    List<T> Function(PreferenciasIndividuaisDoUsuarioModel preferencias);
typedef MobileCardOrderPersist<T extends Object> =
    Future<void> Function(List<T> ordem);

class MobileCardOrderPreferenceController<T extends Object>
    extends ChangeNotifier {
  MobileCardOrderPreferenceController({
    required List<T> ordemPadrao,
    required MobileCardOrderSelector<T> selecionarOrdem,
    required MobileCardOrderPersist<T> persistirOrdem,
    required this.nomeDaTela,
    UsuarioService? usuarioService,
    UsuarioProvider? usuarioProvider,
  }) : _ordemPadrao = List<T>.unmodifiable(ordemPadrao),
       _selecionarOrdem = selecionarOrdem,
       _persistirOrdem = persistirOrdem,
       _usuarioService = usuarioService ?? UsuarioService(),
       _usuarioProvider = usuarioProvider ?? UsuarioProvider() {
    final PreferenciasIndividuaisDoUsuarioModel? preferencias =
        _usuarioProvider.usuario?.preferenciasIndividuaisDoUsuario;
    _ordem = List<T>.of(
      preferencias == null ? _ordemPadrao : _selecionarOrdem(preferencias),
    );
  }

  final String nomeDaTela;
  final List<T> _ordemPadrao;
  final MobileCardOrderSelector<T> _selecionarOrdem;
  final MobileCardOrderPersist<T> _persistirOrdem;
  final UsuarioService _usuarioService;
  final UsuarioProvider _usuarioProvider;

  late List<T> _ordem;
  bool _inicializado = false;
  bool _ordemAlteradaNestaSessao = false;
  bool _descartado = false;

  List<T> get ordem => List<T>.unmodifiable(_ordem);

  void inicializar() {
    if (_inicializado) return;
    _inicializado = true;
    _usuarioProvider.addListener(_aoAlterarUsuario);
    unawaited(_restaurarDoCache());
  }

  void reordenar(T movido, T destino) {
    final int indiceOrigem = _ordem.indexOf(movido);
    final int indiceDestino = _ordem.indexOf(destino);
    if (indiceOrigem < 0 ||
        indiceDestino < 0 ||
        indiceOrigem == indiceDestino) {
      return;
    }

    final List<T> novaOrdem = List<T>.of(_ordem)..removeAt(indiceOrigem);
    final int indiceInsercao = indiceDestino > novaOrdem.length
        ? novaOrdem.length
        : indiceDestino;
    novaOrdem.insert(indiceInsercao, movido);

    _ordemAlteradaNestaSessao = true;
    _aplicarOrdem(novaOrdem);
    unawaited(_salvar(novaOrdem));
  }

  Future<void> _restaurarDoCache() async {
    final PreferenciasIndividuaisDoUsuarioModel? preferenciasCache =
        await _usuarioService.carregarPreferenciasIndividuaisDoCache();
    if (_descartado || _ordemAlteradaNestaSessao) return;

    final PreferenciasIndividuaisDoUsuarioModel? preferenciasRemotas =
        _usuarioProvider.usuario?.preferenciasIndividuaisDoUsuario;
    final PreferenciasIndividuaisDoUsuarioModel? preferencias =
        preferenciasRemotas ?? preferenciasCache;
    if (preferencias == null) return;

    _aplicarOrdem(_selecionarOrdem(preferencias));
  }

  void _aoAlterarUsuario() {
    if (_descartado || _ordemAlteradaNestaSessao) return;
    final PreferenciasIndividuaisDoUsuarioModel? preferencias =
        _usuarioProvider.usuario?.preferenciasIndividuaisDoUsuario;
    if (preferencias == null) return;
    _aplicarOrdem(_selecionarOrdem(preferencias));
  }

  void _aplicarOrdem(List<T> novaOrdem) {
    final List<T> ordemNormalizada = _normalizar(novaOrdem);
    if (listEquals(_ordem, ordemNormalizada)) return;
    _ordem = List<T>.of(ordemNormalizada);
    notifyListeners();
  }

  List<T> _normalizar(List<T> ordem) {
    if (ordem.length == _ordemPadrao.length &&
        ordem.toSet().length == _ordemPadrao.length &&
        ordem.toSet().containsAll(_ordemPadrao)) {
      return ordem;
    }
    return _ordemPadrao;
  }

  Future<void> _salvar(List<T> ordem) async {
    try {
      await _persistirOrdem(List<T>.unmodifiable(ordem));
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao salvar ordem dos cards de $nomeDaTela: $error\n$stackTrace',
      );
    }
  }

  @override
  void dispose() {
    _descartado = true;
    if (_inicializado) {
      _usuarioProvider.removeListener(_aoAlterarUsuario);
    }
    super.dispose();
  }
}
