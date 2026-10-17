import 'package:flutter/material.dart';
import 'package:sixpos/data/services/fornecedor_usuario/fornecedor_usuario_api_client.dart';

/// Editor de autorizacoes especificas por colaborador e comercio.
/// O backend verifica o perfil do administrador em cada consulta/alteracao.
class FornecedoresPermissoesPage extends StatefulWidget {
  const FornecedoresPermissoesPage({super.key, required this.api});
  final FornecedorUsuarioApiClient api;

  @override
  State<FornecedoresPermissoesPage> createState() =>
      _FornecedoresPermissoesPageState();
}

class _FornecedoresPermissoesPageState extends State<FornecedoresPermissoesPage> {
  static const permissoes = <String, String>{
    'FORNECEDORES_CONSULTAR': 'Consultar',
    'FORNECEDORES_CADASTRAR': 'Cadastrar',
    'FORNECEDORES_EDITAR': 'Editar',
    'FORNECEDORES_INATIVAR': 'Ativar / inativar',
  };
  late Future<List<FornecedorColaboradorPermissoes>> _consulta;
  String? _salvandoId;

  @override
  void initState() {
    super.initState();
    _consulta = widget.api.listarPermissoesColaboradores();
  }

  void _atualizar() => setState(() {
    _consulta = widget.api.listarPermissoesColaboradores();
  });

  Future<void> _salvar(
      FornecedorColaboradorPermissoes colaborador, String permissao, bool ativo) async {
    if (_salvandoId != null) return;
    setState(() => _salvandoId = colaborador.vinculoId);
    try {
      final atuais = colaborador.permissoes.toSet();
      if (ativo) {
        atuais.add(permissao);
      } else {
        atuais.remove(permissao);
      }
      await widget.api.atualizarPermissoesColaborador(
          colaborador.vinculoId, atuais.toList());
      if (mounted) _atualizar();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Não foi possível salvar a permissão: $error'),
        ));
      }
    } finally {
      if (mounted) setState(() => _salvandoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Permissões de fornecedores',
              style: theme.textTheme.titleLarge)),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _atualizar, icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ]),
        Text('Autorizações por colaborador e por comércio. Não alteram as permissões de clientes.',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        Expanded(child: FutureBuilder<List<FornecedorColaboradorPermissoes>>(
          future: _consulta,
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(
                'Não foi possível consultar as permissões: ${snapshot.error}',
                textAlign: TextAlign.center,
              ));
            }
            final colaboradores = snapshot.data ?? const [];
            if (colaboradores.isEmpty) {
              return const Center(child: Text('Nenhum colaborador ativo neste comércio.'));
            }
            return ListView.builder(
              itemCount: colaboradores.length,
              itemBuilder: (context, index) {
                final item = colaboradores[index];
                final ocupado = _salvandoId != null;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.badge_outlined),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          item.email.isEmpty ? 'Colaborador ${index + 1}' : item.email,
                          style: theme.textTheme.titleSmall,
                        )),
                        if (_salvandoId == item.vinculoId)
                          const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ]),
                      for (final permission in permissoes.entries)
                        SwitchListTile.adaptive(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(permission.value),
                          value: item.permissoes.contains(permission.key),
                          onChanged: ocupado
                              ? null : (valor) => _salvar(item, permission.key, valor),
                        ),
                    ]),
                  ),
                );
              },
            );
          },
        )),
      ]),
    );
  }
}
