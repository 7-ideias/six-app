import 'package:sixpos/presentation/navigation/web_navigation_item.dart';
import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';

/// Converts the current authorization provider into the declarative permission
/// set understood by the Web navigation registry.
///
/// This adapter does not own authorization rules and does not render UI. It is
/// only the bridge between the existing provider and the Web navigation model.
abstract final class WebNavigationPermissionAdapter {
  static Set<WebNavigationPermission> permissionsFor(
    ColaboradorAutorizacoesProvider provider,
  ) {
    if (!_canUseProviderPermissions(provider)) {
      return const <WebNavigationPermission>{};
    }

    if (provider.ehAdministrador) {
      return WebNavigationPermission.values.toSet();
    }

    return <WebNavigationPermission>{
      if (provider.podeFazerVenda) WebNavigationPermission.podeFazerVenda,
      if (provider.podeLancarAssistenciaTecnica)
        WebNavigationPermission.podeLancarAssistenciaTecnica,
      if (provider.podeEditarCliente) WebNavigationPermission.podeEditarCliente,
      if (provider.podeCadastrarProduto)
        WebNavigationPermission.podeCadastrarProduto,
      if (provider.podeEditarProduto) WebNavigationPermission.podeEditarProduto,
      if (provider.podeVerEstoqueDeProduto)
        WebNavigationPermission.podeVerEstoqueDeProduto,
      if (provider.podeGerarRelatorio)
        WebNavigationPermission.podeGerarRelatorio,
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
  ) {
    return _canUseProviderPermissions(provider);
  }

  static bool _canUseProviderPermissions(
    ColaboradorAutorizacoesProvider provider,
  ) {
    return provider.ehAdministrador ||
        provider.autorizacoesCarregadasComSucesso;
  }
}
