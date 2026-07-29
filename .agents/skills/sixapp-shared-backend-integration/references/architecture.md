# Arquitetura de referência do SixApp

Confirme sempre o código atual antes de implementar.

## Diagnóstico

O SixApp possui arquitetura parcialmente consolidada e padrões concorrentes.

Tecnologias predominantes:

- Flutter Web, Android e iOS;
- `package:http`;
- `http_interceptor` em poucos módulos legados;
- Provider/ChangeNotifier;
- serialização JSON manual;
- módulos estáticos de composição em alguns domínios;
- nenhuma camada Repository consolidada;
- nenhuma geração automática de DTOs.

Não existe um cliente HTTP universal. `createHttpClient()` é uma factory por plataforma, não um client completo de autenticação e erros.

`AuthService` é a fonte atual de access token, refresh token, usuário e `idUnicoDaEmpresa`.

## Referências positivas

### Atendimento técnico — compartilhamento Web/Mobile

- `lib/domain/services/atendimento_tecnico/atendimento_tecnico_service.dart`
- `lib/data/services/atendimento_tecnico/atendimento_tecnico_api_client.dart`
- `lib/data/models/atendimento_tecnico_models.dart`
- `lib/presentation/screens/atendimentos_tecnicos_web_page.dart`
- `lib/presentation/screens/atendimentos_tecnicos_mobile_screen.dart`
- `lib/presentation/screens/atendimento_tecnico_mobile_screen.dart`
- `lib/presentation/screens/atendimento_tecnico_editar_dialog.dart`
- `lib/presentation/screens/atendimento_tecnico_editar_mobile_screen.dart`

Padrão:

```text
UI Web --------\
                -> AtendimentoTecnicoService
UI Mobile -----/             |
                      AtendimentoTecnicoApiClient
                                |
                     models/inputs compartilhados
```

### Regionalização — DTO, mapper e domínio

- `lib/domain/services/regionalizacao/regionalizacao_service.dart`
- `lib/data/services/regionalizacao/regionalizacao_api_client.dart`
- `lib/data/models/regionalizacao_models.dart`
- `lib/domain/models/regionalizacao_models.dart`
- `lib/mappers/configuracao_regionalizacao_mapper.dart`
- `lib/providers/locale_settings_provider.dart`

Padrão:

```text
Response DTO -> Mapper -> Model de domínio
```

### Operação/PDV — mapper e composição

- `lib/core/di/operacao_module.dart`
- `lib/domain/services/operacao/operacao_service.dart`
- `lib/mappers/operacao_mapper.dart`
- `lib/pagina_principal_web.dart`
- `lib/presentation/screens/pdv_mobile_screen_base.dart`

### Cliente usuário — client testável

- `lib/data/services/cliente_usuario/cliente_usuario_api_client.dart`
- `lib/data/models/cliente_usuario_models.dart`
- `lib/core/di/cliente_usuario_module.dart`

Observe a injeção de `http.Client` e providers de token/empresa.

### Infraestrutura de plataforma

- `lib/core/services/auth_service.dart`
- `lib/core/services/http_client_factory.dart`
- `lib/core/services/http_client_factory_web.dart`
- `lib/core/services/http_client_factory_stub.dart`
- `lib/core/utils/pdf_download.dart`
- `lib/core/utils/pdf_download_web.dart`
- `lib/core/utils/pdf_download_stub.dart`

## Contraexemplos

### Tela inicial duplicada

- `lib/data/services/telainicial_web/tela_inicial_api_client.dart`
- `lib/domain/services/telainicial_web/tela_inicial_web_service.dart`

### ProdutoService acumulando responsabilidades

- `lib/core/services/produto_service.dart`
- `lib/providers/produto_provider.dart`

Problemas observados: service também atua como client, headers repetidos, provider conhece autenticação, uso de `dynamic` e logging potencialmente sensível.

### Dependência de data para presentation

- `lib/data/models/caixa_models.dart`

### Maps dinâmicos

- `lib/core/services/agenda_financeira_lancamento_service.dart`

### Service atualizando Provider

- `lib/domain/services/telainicial_web/tela_inicial_web_service.dart`

### Logging sensível

- `lib/core/network/logging_interceptor.dart`

## Convenção recomendada

```text
lib/data/models/<dominio>_models.dart
lib/data/services/<dominio>/<dominio>_api_client.dart
lib/domain/models/<dominio>_models.dart       # somente se necessário
lib/mappers/<dominio>_mapper.dart             # somente se necessário
lib/domain/services/<dominio>/<dominio>_service.dart
lib/core/di/<dominio>_module.dart              # conforme ciclo de vida
```

## Matriz de decisão

| Situação | Decisão |
|---|---|
| Mesmo endpoint já usado no Web | Mobile reutiliza client, contratos, parsing e service |
| Mesmo endpoint já usado no Mobile | Web reutiliza client, contratos, parsing e service |
| CRUD simples | DTO/model serializável compartilhado pode ser consumido diretamente |
| Transporte difere do domínio | Response DTO + mapper + model de domínio |
| Jornada Web e Mobile diferente | Providers/view models podem ser distintos |
| Diferença de cookies, download ou storage | Isolar em factory, adapter ou conditional import |
| Service apenas replica client | Não criar camada adicional sem valor |
| Módulo não usa Repository | Não introduzir Repository por convenção externa |
| Contrato conhecido retorna `Map` | Criar response tipado se estiver dentro do escopo |
| Código legado duplicado | Reutilizar o caminho mais estruturado e migrar somente o necessário |

## Testes mínimos

Use `package:http/testing.dart` e `MockClient` para cobrir parsing de request/response, sucesso, erro HTTP, vazio/204, resposta inválida e mapper/service quando houver lógica.
