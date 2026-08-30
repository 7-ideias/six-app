import 'package:sixpos/presentation/navigation/web_navigation_item.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';

abstract final class WebNavigationPermissionAdapter {
  static Set<WebNavigationPermission> permissionsFor(
    ColaboradorAutorizacoesProvider provider,
  ) {
    if (!_canUseProviderPermissions(provider)) {
      return const <WebNavigationPermission>{};
    }
    if (provider.ehAdministrador) {
      final Set<WebNavigationPermission> permissions =
          WebNavigationPermission.values.toSet();
      if (!provider.ehSuperUsuario) {
        permissions.remove(WebNavigationPermission.podeAcessarUsuariosSixo);
      }
      return permissions;
    }
    return <WebNavigationPermission>{
      if (provider.podeFazerVenda) WebNavigationPermission.podeFazerVenda,
      if (provider.podeFazerVenda || provider.podeVerQuantoVendeu)
        WebNavigationPermission.podeConsultarVendas,
      if (provider.podeFazerDevolucao)
        WebNavigationPermission.podeFazerDevolucao,
      if (provider.podeLancarAssistenciaTecnica)
        WebNavigationPermission.podeLancarAssistenciaTecnica,
      if (provider.podeEditarCliente) WebNavigationPermission.podeEditarCliente,
      if (provider.podeCadastrarProduto)
        WebNavigationPermission.podeCadastrarProduto,
      if (provider.podeEditarProduto) WebNavigationPermission.podeEditarProduto,
      if (provider.podeVerEstoqueDeProduto)
        WebNavigationPermission.podeVerEstoqueDeProduto,
      if (provider.podeAcessarCatalogo)
        WebNavigationPermission.podeAcessarCatalogo,
      if (provider.podeAcessarEtiquetas)
        WebNavigationPermission.podeAcessarEtiquetas,
      if (provider.podeGerarRelatorio)
        WebNavigationPermission.podeGerarRelatorio,
      if (!provider.ehColaborador && provider.ehSuperUsuario)
        WebNavigationPermission.podeGerenciarDesempenho,
      if (provider.ehSuperUsuario)
        WebNavigationPermission.podeAcessarUsuariosSixo,
      if (provider.podeVerQuantoVendeu)
        WebNavigationPermission.podeAcessarFinanceiro,
      if (provider.podeReceberNoCaixa)
        WebNavigationPermission.podeReceberNoCaixa,
    };
  }

  static bool includeUnresolvedFor(ColaboradorAutorizacoesProvider provider) {
    return _canUseProviderPermissions(provider) && provider.ehAdministrador;
  }

  static bool canApplySidebarFiltering(
    ColaboradorAutorizacoesProvider provider,
  ) => _canUseProviderPermissions(provider);

  static bool _canUseProviderPermissions(
    ColaboradorAutorizacoesProvider provider,
  ) => provider.ehAdministrador || provider.autorizacoesCarregadasComSucesso;
}
