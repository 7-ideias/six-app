import 'package:flutter/material.dart';
import 'package:sixpos/data/services/fornecedor_usuario/fornecedor_usuario_api_client.dart';
import 'fornecedores_web_page.dart';

/// Usa a mesma listagem/adaptacao responsiva da Web no fluxo mobile.
class FornecedoresMobileScreen extends StatelessWidget {
  const FornecedoresMobileScreen({super.key, this.apiClient});
  final FornecedorUsuarioApiClient? apiClient;
  @override
  Widget build(BuildContext context) =>
      FornecedoresWebPage(apiClient: apiClient);
}
