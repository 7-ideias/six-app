# Backend de configurações, traduções e regionalização

Esta referência documenta o contrato atual do backend `sixBack` usado pelo Flutter para i18n e regionalização.

## I18n backend

Controller:

- `../sixBack/src/main/java/br/com/six/backend/controller/traducao/TraducaoController.java`
- Base: `/public/api/i18n`
- Operação: `GET /{locale}`

Response:

- `../sixBack/src/main/java/br/com/six/backend/controller/response/TraducaoResponse.java`
- Campos: `locale`, `version`, `messages`.

Service e cache:

- `../sixBack/src/main/java/br/com/six/backend/service/traducao/TraducaoService.java`
- Usa `@Cacheable(value = "traducoes", key = "#locale")`.
- Calcula ETag por locale, versão e mensagens.
- Suporta `If-None-Match` e resposta `304 Not Modified`.
- Fallback: locale exato, depois idioma, depois `pt-BR`.

Persistência:

- `../sixBack/src/main/java/br/com/six/backend/model/traducao/TraducaoEntity.java`
- Collection Mongo: `traducoes`.
- Repository: `TraducaoRepository`.

Seed:

- `../sixBack/src/main/java/br/com/six/backend/config/TraducaoSeeder.java`
- Locales atuais: `pt-BR`, `en-US`, `es-ES`.
- Lê arquivos base `src/main/resources/i18n/{locale}.json`.
- Lê namespaces em `src/main/resources/i18n/{locale}/*.json`.
- Mescla mensagens e converte chaves com ponto em mapa aninhado por limitação do Mongo.

Diretriz atual do backend:

- JSONs versionados no backend são fonte de verdade para textos estáticos do app.
- MongoDB é cache/leitura rápida sem edição manual como fluxo principal.
- Textos comerciais/editáveis por administrador devem usar configuração própria quando necessário, não os JSONs estáticos.

## Regionalização backend

Controller:

- `../sixBack/src/main/java/br/com/six/backend/controller/telainicial/InformacoesBasicasParaMontarCaixaController.java`
- Base: `/private/api/caixa`
- `GET /informacoes-basicas`
- `GET /configuracoes/regionalizacao`
- `PUT /configuracoes/regionalizacao`

Tenant e permissão:

- Header obrigatório do comércio: `idUnicoDaEmpresa`.
- Controller valida vínculo usuário-empresa com `ValidadorAcessoEmpresaDoUsuario`.
- O usuário autenticado vem de `SecurityContextHolder`.

Request:

- `../sixBack/src/main/java/br/com/six/backend/controller/request/SalvarConfiguracaoRegionalizacaoRequest.java`
- Campos obrigatórios: `languageCode`, `countryCode`, `currencyCode`, `timeZone`, `dateFormat`, `timeFormat`, `decimalSeparator`, `thousandSeparator`, `firstDayOfWeek`, `numberPattern`, `decimalPlaces`, `allowMultipleCurrencies`, `applyFinancialRounding`.
- `decimalPlaces` aceita 0 a 6.

Response:

- `../sixBack/src/main/java/br/com/six/backend/controller/response/ConfiguracaoRegionalizacaoResponse.java`
- Mesmo conjunto técnico de campos, com `id` e `idEmpresa`.

Service:

- `../sixBack/src/main/java/br/com/six/backend/service/configuracao/ConfiguracaoRegionalizacaoService.java`
- Busca configuração por empresa, cria inicial quando ausente e salva dentro de `ConfiguracaoEmpresaDocument`.

Persistência:

- `../sixBack/src/main/java/br/com/six/backend/document/configuracao/ConfiguracaoEmpresaDocument.java`
- Collection Mongo: `configuracoes_empresa`.
- Campo embutido: `regionalizacao`.
- Documento: `RegionalizacaoDocument`.
- Repository: `ConfiguracaoEmpresaRepository`.

Fallback inicial:

- `../sixBack/src/main/java/br/com/six/backend/util/ConfiguracaoEmpresaInicialUtil.java`.
- Atenção: fallback atual combina `languageCode: en`, `countryCode: US` com `currencyCode: BRL`, timezone e formatos brasileiros. Trate como risco arquitetural antes de ampliar regras dependentes de default.

## Contrato consumido no Flutter

Cliente Flutter:

- `lib/data/services/regionalizacao/regionalizacao_api_client.dart`.

Modelos e mapper:

- `lib/data/models/regionalizacao_models.dart`;
- `lib/domain/models/regionalizacao_models.dart`;
- `lib/mappers/configuracao_regionalizacao_mapper.dart`.

Service e provider:

- `lib/domain/services/regionalizacao/regionalizacao_service.dart`;
- `lib/providers/locale_settings_provider.dart`.

Consumo compartilhado:

- `main.dart` registra `LocaleSettingsProvider` globalmente.
- Web e Mobile devem consumir o mesmo provider e service.
- `InformacoesBasicasCaixaResponse` também carrega `regionalizacao` em fluxos de caixa.

## Regras para evolução de contrato

- Preserve compatibilidade de campos existentes.
- Envie e persista códigos técnicos, não labels localizados.
- Quando adicionar configuração por tenant, prefira campo opcional com fallback claro.
- Quando expuser mensagens configuráveis, diferencie texto estático do app, texto comercial editável e mensagem dinâmica de domínio.
- Para erros de regra de negócio, prefira códigos estáveis quando o frontend precisar traduzir.
- Não altere endpoint compartilhado por Web/Mobile sem validar ambos.
- Não duplique DTO, client ou parser no Flutter para o mesmo recurso.

## Duplicidades e riscos observados

- Existem telas Flutter com strings, moeda e data hardcoded; corrija incrementalmente quando o fluxo for tocado.
- `ProdutoService` concentra responsabilidades e ainda é chamado diretamente por algumas telas; não replique esse padrão em integrações novas.
- Há duplicidade parcial entre tela inicial Web e Mobile; novas integrações compartilhadas devem usar infraestrutura única.
- O modelo de caixa importa presentation em camada data, violando separação de camadas.
- Mensagens de validação Java em annotations ainda aparecem em português técnico; antes de expor ao usuário, avalie códigos ou i18n.
