# Imagens publicadas pelo painel Imagens do SixoApp

Use este fluxo quando um banner, cabeçalho ou cartão do aplicativo deve mudar com uma publicação do painel SUPER. A tela de início e o seletor de itens do PDV são exemplos. Fotos do catálogo de produtos pertencem ao cadastro do produto e têm outro ciclo de vida.

## Cadastro e resolução no SixBack

1. Registre no enum `VisualAssetCatalog.Slot` a finalidade, a plataforma, o código usado pela tela, a chave de tradução, as dimensões recomendadas e o modo de exibição. Crie entradas distintas quando Web e Mobile aceitarem artes independentes. Defina o comportamento sem arte com o responsável pela tela. No PDV os quatro espaços começam vazios.
2. Exponha os espaços no painel `admin_visual_assets_web_page.dart`, com nomes distinguíveis por plataforma e finalidade em português, inglês e espanhol. O painel e o `VisualAssetAdminService` já cuidam de upload, otimização, escopo, histórico, agendamento e publicação.
3. No endpoint de leitura autenticado, valide o vínculo entre o usuário do token e a empresa do header `idUnicoDaEmpresa`. Carregue o perfil e delegue a `VisualAssetResolverService.resolve` a escolha da arte ativa. Essa resolução contempla empresa, segmento e padrão global no ambiente aplicável, com herança de LIVE em DEV. A edição no painel segue a autorização SUPER existente.
4. Entregue a URL pública versionada retornada pelo resolvedor. O JSON contextual deve ser revalidado ao abrir a tela e quando a versão mudar. A resposta do PDV usa `Cache-Control: no-store`. Os bytes otimizados da arte podem usar cache longo, pela URL imutável. A ausência de uma entrada é válida.

O PDV usa `GET /private/api/pdv/selecao/assets?plataforma=WEB|MOBILE` e devolve um mapa com as entradas disponíveis entre `PRODUTO` e `SERVICO`. No Flutter, use um único método de serviço para ambas as interfaces.

## Atualização com a tela aberta

- Reutilize a conexão STOMP da sessão e o `VisualAssetSyncService`. Uma publicação gera `ASSETS_VERSION_CHANGED` em `/topic/system/assets`. O evento informa versão e ambiente. O cliente consulta o backend para obter a composição efetiva do seu comércio.
- Assine `changes` antes de inicializar a sincronização. O serviço central reconcilia com `GET /private/api/assets/version` na inicialização, no retorno ao primeiro plano, na próxima ativação agendada e periodicamente enquanto há consumidores. Isso recupera eventos perdidos.
- Observe também a troca de comércio e do perfil. Remova da tela as URLs do contexto anterior e descarte respostas atrasadas. Compare a geração da requisição após operações assíncronas e antes de persistir. Cancele as assinaturas ao descartar o consumidor.
- Atualize apenas o estado do componente visual. Abrir o PDV, buscar itens, alternar categorias e montar a venda devem funcionar enquanto as fotos carregam. Uma nova composição pode adicionar, substituir ou remover uma imagem.

## Persistência e exibição no Flutter

| Plataforma | Recuperação e armazenamento |
| --- | --- |
| Web | Exiba com `SixCachedNetworkImage`. O provedor web usa Cache Storage para bytes públicos, identificado pela URL completa com versão. Há deduplicação, limites por volume e idade e recuperação via HTTP se o cache estiver indisponível. O manifesto do comércio é consultado na API. |
| Android e iOS | Use `SixCachedNetworkImage` e `SixVisualAssetsCache` para os bytes em disco. Quando houver manifesto para restauração, use `VisualAssetManifestCacheService` com finalidade, empresa, ambiente e versão. Publique o manifesto local somente após o prefetch das imagens. Uma composição vazia confirmada pelo servidor também deve substituir a anterior. |

Use `PdvSelecaoImagensController` como referência para isolar as requisições de arte, restaurar o manifesto compatível e revalidá-lo em segundo plano. Preserve as URLs versionadas na chave dos widgets de imagem. No desenvolvimento com o emulador Android, uma URL local do SixBack pode anunciar localhost. Se a API estiver configurada com 10.0.2.2, o PDV usa esse host também para a imagem, preservando a porta, o caminho e a versão. Mantenha a categoria identificável pelo nome e o botão operável durante falha ou ausência da foto. Use as cores do tema e garanta contraste sobre a imagem.

## Verificação

Teste catálogo vazio e preenchido, zero, uma e duas imagens, substituição e remoção com a tela aberta, novo processo com cache, troca de empresa, resposta antiga após uma mais nova, retorno ao primeiro plano e indisponibilidade de rede. No PDV, marque um produto e um serviço e confirme que atualização de foto preserva categorias, quantidades e valor da venda. Na validação integrada use o mesmo ambiente no painel e no cliente.
