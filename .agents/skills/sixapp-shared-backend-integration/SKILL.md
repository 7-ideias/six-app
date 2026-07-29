---
name: sixapp-shared-backend-integration
description: Use ao criar, alterar ou revisar integrações Flutter com o backend do SixApp, especialmente funcionalidades que existem ou poderão existir nas interfaces Web e Mobile. Garante o reaproveitamento de endpoint, ApiClient, requests, responses, models, parsing, mappers, services, autenticação, tenant e erros. Não use para mudanças exclusivamente visuais nem para implementar o backend Java.
---

# Integrações compartilhadas com o backend do SixApp

Implemente integrações com uma única fonte de verdade para Web, Android e iOS. As interfaces gráficas podem ser diferentes; o contrato da API e a camada de comunicação não podem ser recriados por plataforma.

Leia primeiro:

- `AGENTS.md`;
- `.junie/AGENTS.md`, quando existir;
- `references/architecture.md` desta skill;
- os arquivos reais do domínio afetado.

## Resultado obrigatório

Para o mesmo endpoint e domínio, mantenha compartilhados:

- endpoint e parâmetros técnicos;
- request e response de transporte;
- `fromJson` e `toJson`;
- ApiClient;
- autenticação e `idUnicoDaEmpresa`;
- mapper, quando necessário;
- model de domínio, quando existir;
- service e interpretação semântica;
- exceptions e regras de status HTTP.

Podem permanecer específicos por interface ou plataforma:

- widgets e layout;
- navegação;
- estado estritamente de apresentação;
- view models sem parsing HTTP;
- seleção, download e abertura de arquivos;
- armazenamento seguro;
- push, notificações, compartilhamento e impressão;
- adapters e imports condicionais.

Providers Web e Mobile não precisam ser idênticos quando as jornadas forem diferentes. Ambos devem depender da mesma integração compartilhada.

## 1. Investigue antes de editar

Antes de criar qualquer classe:

1. Pesquise o endpoint literal, rota parcial e método HTTP.
2. Pesquise nomes do domínio, requests, responses, models, clients, services, providers e telas.
3. Localize as telas Web e Mobile relacionadas, inclusive implementações futuras ou parciais.
4. Trace o fluxo existente: `UI -> estado -> service -> ApiClient -> endpoint -> response`.
5. Confirme como são obtidos token, empresa, headers, base URL, client HTTP e erros.
6. Verifique se a integração já existe em outra interface.
7. Verifique duplicações, código legado e contratos equivalentes.
8. Para tarefas amplas, apresente um plano curto de reaproveitamento antes de editar.

Use pesquisas como:

```bash
rg -n "endpoint|nomeDoDominio|ApiClient|Service|Request|Response|fromJson" lib test
git status
git diff
```

Não conclua que a integração não existe após uma única busca.

## 2. Escolha a estratégia

### Integração já existe

Reutilize ApiClient, request, response, parsing, mapper e service existentes. Crie somente a UI ausente, o estado de apresentação específico, pequenos métodos compartilhados realmente faltantes e adapters tecnicamente necessários.

Não copie a integração para uma pasta `web`, `mobile` ou para dentro da tela.

### Integração existe parcialmente

Complete a camada compartilhada antes de conectar a segunda interface. Exemplos:

- mover parsing duplicado para o model compartilhado;
- adicionar método ao ApiClient existente;
- adicionar request/response tipado;
- criar service compartilhado quando houver regra ou orquestração comum;
- isolar diferença de plataforma em factory ou conditional import.

Não faça migração ampla de módulos legados fora do escopo.

### Integração nova

Siga, proporcionalmente ao domínio:

```text
lib/data/models/<dominio>_models.dart
lib/data/services/<dominio>/<dominio>_api_client.dart
lib/domain/models/<dominio>_models.dart       # somente quando transporte != domínio
lib/mappers/<dominio>_mapper.dart             # somente quando há conversão real
lib/domain/services/<dominio>/<dominio>_service.dart
lib/core/di/<dominio>_module.dart              # quando o ciclo de vida justificar
```

Não introduza Repository apenas por preferência arquitetural. O SixApp ainda não consolidou essa camada.

## 3. Defina o contrato compartilhado

Regra central:

> Cada endpoint deve possuir uma única representação de transporte compartilhada e, quando houver model de domínio, um único mapper e uma única representação de domínio compartilhada. Web e Mobile não devem criar contratos, parsers, clients ou interpretações semânticas duplicadas.

Use DTO/model compartilhado diretamente quando o caso for CRUD simples, o contrato for estável, não houver transformação relevante e o mesmo objeto atender Web e Mobile.

Use response DTO + mapper + domínio quando a estrutura do backend for inadequada ao domínio, houver normalização ou composição significativa, múltiplos endpoints alimentarem o mesmo conceito ou códigos de transporte não devam chegar à apresentação.

View model específico é permitido apenas para estado de apresentação, como formatação, seleção, expansão, agrupamento visual, loading, animação e validação temporária. Ele não pode implementar `fromJson`, redefinir o contrato, montar headers ou interpretar status HTTP.

## 4. Implemente o ApiClient compartilhado

Prefira o padrão `XApiClient` + `HttpXApiClient` quando o módulo exigir abstração e injeção. Para módulos simples, siga a convenção predominante mais próxima sem duplicar código.

Regras:

1. Declare o endpoint em um único lugar.
2. Use `AppConfig.baseUrl`.
3. Use `createHttpClient()` quando compatível.
4. Permita injeção de `http.Client` quando melhorar teste, cancelamento ou ciclo de vida.
5. Obtenha token e empresa pela infraestrutura existente, normalmente `AuthService`.
6. Não monte `Authorization` ou `idUnicoDaEmpresa` em widgets.
7. Não receba `BuildContext` em data/domain.
8. Não importe `presentation` em `data` ou `domain`.
9. Preserve diferenças Web/Mobile apenas quando técnicas, como cookies e download.
10. Não registre token, cookies, headers ou body sensível.

Enquanto não houver infraestrutura central nova aprovada, siga o padrão de headers do módulo sem criar outra variante:

```dart
{
  'Content-Type': 'application/json',
  'idUnicoDaEmpresa': empresaId,
  'Authorization': 'Bearer $token',
}
```

Não faça centralização global de headers como efeito colateral de tarefa localizada.

## 5. Trate responses e erros de forma tipada

- Faça parsing uma única vez.
- Evite `Map<String, dynamic>` como retorno público quando o contrato for conhecido.
- Não crie um segundo model para a outra interface.
- Preserve o significado dos status HTTP conforme o endpoint.
- Use exception tipada da integração, com status e mensagem/body seguro.
- Diferencie, quando relevante, erro HTTP, resposta inválida, parsing, ausência permitida e lista vazia.
- Não exponha erro cru ou dado sensível ao usuário.
- A apresentação converte o erro técnico em mensagem localizada.
- Não substitua códigos técnicos por labels traduzidos.

## 6. Implemente service somente quando houver valor

Crie ou reutilize `XService` quando houver regra compartilhada, mapper, composição de chamadas, normalização, interpretação semântica ou operação usada por várias interfaces.

Se o service apenas duplicar cada método do client e o padrão do módulo usa client direto, não invente uma camada nova durante alteração pequena.

O service não pode atualizar Provider diretamente.

## 7. Componha dependências sem duplicar

Siga o mecanismo existente mais próximo:

- módulo estático em `lib/core/di`;
- Provider raiz para estado global;
- injeção por construtor;
- dependência opcional em tela apenas para testes.

Evite criar `http.Client`, ApiClient ou Service repetidamente em cada tela sem necessidade. Não introduza GetIt, Injectable ou nova biblioteca de DI em tarefa localizada.

## 8. Preserve diferenças legítimas de plataforma

Use factory, adapter ou conditional import para:

- `BrowserClient(withCredentials: true)` no Web;
- download Web versus Mobile;
- armazenamento;
- arquivos;
- notificações e push;
- compartilhamento e impressão.

A diferença deve começar depois do contrato compartilhado sempre que possível.

Não crie `WebApiClient` e `MobileApiClient` para o mesmo endpoint sem demonstrar diferença técnica inevitável.

## 9. Conecte as interfaces

- Ambas devem chegar ao mesmo ApiClient ou service.
- Ambas devem usar os mesmos requests e responses.
- Parsing e regra semântica devem ocorrer uma vez.
- Estado visual pode ser diferente.
- Não force o mesmo Provider quando isso prejudicar jornadas distintas.
- Não mova regras de UI para data.
- Não mova detalhes HTTP para Providers.

Antes de concluir, demonstre:

```text
Tela Web -> ... -> integração compartilhada
Tela Mobile -> ... -> integração compartilhada
```

## 10. Teste proporcionalmente ao escopo

O projeto ainda possui pouca cobertura. Não crie infraestrutura ampla sem solicitação.

Para integração nova ou contrato relevante, priorize:

1. `fromJson` válido;
2. campos opcionais relevantes;
3. `toJson` do request;
4. sucesso do client;
5. status inesperado;
6. `204` ou vazio, quando aplicável;
7. resposta inválida;
8. mapper, quando houver;
9. service, quando contiver regra.

Prefira `MockClient` de `package:http/testing.dart` quando suficiente.

Execute, conforme o escopo:

```bash
flutter analyze
flutter test <testes-relacionados>
```

Não corrija falhas preexistentes fora do escopo; registre-as.

## 11. Proibições

Nunca:

- criar clients separados por interface para o mesmo endpoint sem necessidade comprovada;
- duplicar request, response, model, parser, mapper ou service por plataforma;
- chamar HTTP diretamente em widget;
- montar bearer token ou tenant na tela;
- duplicar `fromJson`;
- devolver mapa dinâmico quando já existir tipo adequado;
- fazer `data` ou `domain` depender de `presentation`;
- usar service para atualizar Provider diretamente;
- logar token, cookie, headers ou body sensível;
- introduzir Repository só para seguir arquitetura genérica;
- alterar backend ou contrato para acomodar layout;
- fazer refatoração ampla, formatação em massa, commit ou push sem pedido explícito.

## 12. Validação final

Antes de concluir:

```bash
git status
git diff --stat
git diff
```

Confirme:

- um único endpoint, request, response e parser;
- um único mapper, se houver;
- um único service/regra compartilhada;
- autenticação e tenant fora da UI;
- nenhuma dependência data/domain -> presentation;
- Web e Mobile reutilizam a integração;
- diferenças específicas estão isoladas;
- não houve mudança fora do escopo;
- não há logs sensíveis.

## 13. Relatório final obrigatório

Apresente:

1. funcionalidade e endpoint;
2. integração existente reutilizada;
3. arquivos compartilhados;
4. arquivos específicos de Web;
5. arquivos específicos de Mobile;
6. fluxo Web até o backend;
7. fluxo Mobile até o backend;
8. request, response e model utilizados;
9. mapper e service, quando houver;
10. autenticação e `idUnicoDaEmpresa`;
11. tratamento de erros e status;
12. diferenças legítimas de plataforma;
13. testes e comandos executados;
14. resultado de `flutter analyze`;
15. confirmação de ausência de duplicação;
16. limitações e pendências;
17. confirmação de que não houve commit nem push.
