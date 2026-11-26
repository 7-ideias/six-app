import 'package:flutter/material.dart';
import '../../data/services/unidades/catalogo_unidades.dart';
import 'unidade_editor.dart';

mixin UnidadeSelecaoState<T extends StatefulWidget> on State<T> {
  CatalogoUnidades? catalogo;
  bool erroUnidades = false;

  Future<CatalogoUnidades> buscarCatalogo() => UnidadesApi.carregar();
  void catalogoAlterado(CatalogoUnidades novo) {}
  Future<void> carregarUnidades() async {
    if (mounted) setState(() => erroUnidades = false);
    try {
      final novo = await buscarCatalogo();
      if (mounted)
        setState(() {
          catalogo = novo;
          catalogoAlterado(novo);
        });
    } catch (_) {
      if (mounted) setState(() => erroUnidades = true);
    }
  }

  Future<Unidade?> editarOpcao({Unidade? unidade, required bool mobile}) async {
    final anterior = catalogo;
    if (anterior == null || !anterior.podeEditar) return null;
    final novo = await editarUnidade(
      context,
      anterior,
      unidade: unidade,
      mobile: mobile,
    );
    if (!mounted) return null;
    if (novo == null) {
      await carregarUnidades();
      return null;
    }
    setState(() {
      catalogo = novo;
      catalogoAlterado(novo);
    });
    return unidade == null ? novo.unidades.last : novo.buscar(unidade.codigo);
  }
}
