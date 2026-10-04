import 'package:flutter/foundation.dart';

import '../core/services/perfil_negocio_change_service.dart';
import '../core/services/perfil_negocio_service.dart';
import '../data/models/perfil_negocio_model.dart';

/// Estado compartilhado da jornada, sem responsabilidade visual.
class PerfilNegocioEditorController extends ChangeNotifier {
  PerfilNegocioEditorController({
    required this.empresaId,
    PerfilNegocioService? service,
  }) : _service = service ?? PerfilNegocioService();

  final String empresaId;
  final PerfilNegocioService _service;

  CatalogoPerfilNegocioModel? catalogo;
  PerfilNegocioEmpresaModel? estado;
  String? segmento;
  String? subsegmento;
  String descricaoOutro = '';
  Set<String> atividades = <String>{};
  String? objetivo;
  bool carregando = false;
  bool salvando = false;
  String? erro;

  int _geracao = 0;
  bool _disposed = false;

  bool get podeEditar => estado?.podeEditar == true;
  bool get configurado => estado?.configurado == true;

  List<String> get subsegmentos {
    for (final SegmentoNegocioModel item
        in catalogo?.segmentos ?? const <SegmentoNegocioModel>[]) {
      if (item.codigo == segmento) return item.subsegmentos;
    }
    return const <String>[];
  }

  Future<void> carregar() async {
    final int geracao = ++_geracao;
    carregando = true;
    erro = null;
    _notify();

    try {
      final PerfilNegocioEmpresaModel estadoCarregado =
          await _service.buscar(empresaId);
      if (_disposed || geracao != _geracao) return;

      CatalogoPerfilNegocioModel catalogoCarregado;
      try {
        catalogoCarregado = await _service.catalogo(empresaId);
      } catch (error) {
        if (!_podeUsarCatalogoLocal(error)) rethrow;
        catalogoCarregado = CatalogoPerfilNegocioModel.fallbackV1();
      }
      if (_disposed || geracao != _geracao) return;

      estado = estadoCarregado;
      catalogo = catalogoCarregado;

      final PerfilNegocioModel perfil = estado!.perfil;
      segmento = estado!.configurado ? perfil.segmentoPrincipal : null;
      subsegmento = estado!.configurado ? perfil.subsegmento : null;
      descricaoOutro = estado!.configurado ? (perfil.descricaoOutro ?? '') : '';
      atividades =
          estado!.configurado ? Set<String>.of(perfil.atividades) : <String>{};
      objetivo = estado!.configurado ? perfil.objetivoPrincipal : null;

      if (!podeEditar) erro = 'forbidden';
    } catch (error) {
      if (_disposed || geracao != _geracao) return;
      erro = _erroKey(error);
    } finally {
      if (!_disposed && geracao == _geracao) {
        carregando = false;
        _notify();
      }
    }
  }

  bool _podeUsarCatalogoLocal(Object error) {
    if (error is! PerfilNegocioException) return true;
    if (error.code == 'CONTEXTO_EMPRESA_ALTERADO') return false;
    if (error.statusCode == 401 || error.statusCode == 403) return false;
    return true;
  }

  void selecionarSegmento(String value) {
    if (salvando) return;
    if (segmento != value) subsegmento = null;
    segmento = value;
    if (value != 'OUTRO') descricaoOutro = '';
    erro = null;
    _notify();
  }

  void atualizarDescricaoOutro(String value) {
    if (salvando) return;
    descricaoOutro = value;
    erro = null;
    _notify();
  }

  void selecionarSubsegmento(String? value) {
    if (salvando) return;
    subsegmento = value;
    erro = null;
    _notify();
  }

  void alternarAtividade(String value) {
    if (salvando) return;
    if (!atividades.add(value)) atividades.remove(value);

    if (value == 'REPAROS_MANUTENCAO' &&
        atividades.contains('REPAROS_MANUTENCAO')) {
      atividades.add('PRESTACAO_SERVICOS');
    }
    if (value == 'PRESTACAO_SERVICOS' &&
        !atividades.contains('PRESTACAO_SERVICOS')) {
      atividades.remove('REPAROS_MANUTENCAO');
    }
    erro = null;
    _notify();
  }

  void selecionarObjetivo(String value) {
    if (salvando) return;
    objetivo = value;
    erro = null;
    _notify();
  }

  bool validarEtapa(int etapa) {
    erro = switch (etapa) {
      0 when segmento == null => 'segmentRequired',
      0 when descricaoOutro.trim().length > 120 => 'descriptionTooLong',
      1
          when !atividades.contains('VENDA_PRODUTOS') &&
              !atividades.contains('PRESTACAO_SERVICOS') =>
        'activityRequired',
      2 when objetivo == null => 'goalRequired',
      _ => null,
    };
    _notify();
    return erro == null;
  }

  AtualizarPerfilNegocioRequest? preparar() {
    if (!podeEditar ||
        segmento == null ||
        objetivo == null ||
        (!atividades.contains('VENDA_PRODUTOS') &&
            !atividades.contains('PRESTACAO_SERVICOS'))) {
      erro = 'review';
      _notify();
      return null;
    }

    return AtualizarPerfilNegocioRequest(
      versao: estado?.versao,
      perfil: PerfilNegocioModel(
        segmentoPrincipal: segmento!,
        subsegmento: subsegmento,
        descricaoOutro:
            segmento == 'OUTRO' && descricaoOutro.trim().isNotEmpty
                ? descricaoOutro.trim()
                : null,
        atividades: atividades,
        objetivoPrincipal: objetivo!,
      ),
    );
  }

  Future<bool> salvar() async {
    if (salvando) return false;
    final AtualizarPerfilNegocioRequest? request = preparar();
    if (request == null) return false;

    salvando = true;
    erro = null;
    _notify();
    try {
      final PerfilNegocioEmpresaModel salvo =
          await _service.salvar(empresaId, request);
      if (_disposed) return false;
      estado = salvo;
      PerfilNegocioChangeService.instance.notifyChanged(empresaId);
      return true;
    } catch (error) {
      if (!_disposed) erro = _erroKey(error);
      return false;
    } finally {
      if (!_disposed) {
        salvando = false;
        _notify();
      }
    }
  }

  String _erroKey(Object error) {
    if (error is PerfilNegocioException) {
      if (error.code == 'CONTEXTO_EMPRESA_ALTERADO') return 'companyChanged';
      if (error.statusCode == 401 || error.statusCode == 403) return 'forbidden';
      if (error.statusCode == 409) return 'conflict';
    }
    return 'loadError';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_geracao;
    _service.dispose();
    super.dispose();
  }
}
