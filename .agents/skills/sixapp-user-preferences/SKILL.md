---
name: sixapp-user-preferences
description: >
  Implementa preferências individuais persistentes no SixApp quando o usuário pede que
  um botão, seletor, filtro, toggle, modo de exibição ou outra opção de UI seja lembrada
  no Mobile, Web ou ambos. Use esta skill para integrar a escolha ao Flutter, cache local,
  endpoint /private/api/eventos/atualizacoes-simples e preferenciasIndividuaisDoUsuario
  no backend Java, incluindo restauração da preferência ao iniciar o app.
---

# SixApp — Preferências individuais do usuário

## Objetivo

Use esta skill sempre que o usuário pedir que uma escolha de interface seja **lembrada/persistida** para ser restaurada posteriormente, por exemplo:

- botão selecionado;
- aba selecionada;
- opção de menu;
- filtro;
- ordenação;
- modo de exibição;
- toggle;
- ocultar/exibir informação;
- preferência visual;
- seção inicial;
- comportamento configurável;
- qualquer escolha do usuário que deva sobreviver ao fechamento ou reinicialização da aplicação.

A implementação deve fazer parte do mecanismo oficial de:

```text
preferenciasIndividuaisDoUsuario
```

e reutilizar o endpoint existente:

```text
/private/api/eventos/atualizacoes-simples
```

Se o código ou documentação local citar o endpoint sem prefixo privado, como
`/api/eventos/atualizacoes-simples`, confirme o path real exposto pelo backend
antes de implementar. No SixApp atual, o path usado pelo frontend autenticado é:

```text
/private/api/eventos/atualizacoes-simples
```

A intenção arquitetural é:

```text
UI
  ↓
Estado Flutter
  ↓
Cache local
  ↓
Backend
```

e, na inicialização:

```text
Cache local pode acelerar a primeira renderização
  ↓
Backend carrega as preferências persistentes do usuário
  ↓
Estado Flutter é sincronizado
  ↓
UI reflete a preferência
  ↓
Cache local é sincronizado
```

O backend é a **persistência durável** da preferência do usuário.

O armazenamento local é um **cache/persistência local para resposta rápida**, e não deve ser tratado como a única fonte da configuração.

Ao usar esta skill, assuma por padrão que o usuário quer o fluxo completo:

```text
alterar a preferência
↓
persistir no backend
↓
persistir/localmente em cache
↓
ao abrir a tela novamente, buscar/restaurar a preferência
```

Não considere a tarefa concluída se você apenas salvar no cache local ou apenas
enviar o evento sem garantir que a tela restaure o valor ao abrir novamente.

---

# Quando esta skill deve ser acionada

Acione esta skill quando o usuário disser algo equivalente a:

```text
quando clicar nesse botão quero salvar a escolha
```

```text
quero que essa opção fique marcada quando abrir novamente
```

```text
salve esse filtro nas preferências do usuário
```

```text
quero lembrar essa configuração no mobile
```

```text
quero a mesma preferência na versão web
```

```text
quando selecionar X, salve para abrir assim na próxima vez
```

```text
persistir isso em preferenciasIndividuaisDoUsuario
```

Não é necessário que o usuário mencione explicitamente o endpoint ou o backend.

Se a intenção for claramente **persistir uma escolha individual do usuário**, considere esta skill aplicável.

---

# Informações obrigatórias da tarefa

Antes de implementar, devem estar definidos somente estes dois pontos:

## 1. Plataforma

Uma destas opções:

```text
MOBILE
WEB
AMBOS
```

Essa informação é obrigatória porque existem preferências específicas da Web e
outras específicas do Mobile. Quando o usuário não explicitar a plataforma,
pergunte. Quando a plataforma já estiver clara, preserve isso em todo o fluxo:
nome do campo, payload, backend e restauração na UI.

## 2. O que deve ser persistido

Deve ser possível determinar:

```text
nome da preferência
```

e:

```text
valor ou conjunto de valores possíveis
```

Exemplos:

```text
modoGestaoMobile = CATALOGO | PESSOAS | FINANCEIRO | GERAL
```

```text
ocultarValoresFinanceirosWeb = true | false
```

```text
modoDeExibicaoProdutosMobile = VERTICAL | GRADE
```

---

# Regra de confirmação com o usuário

O objetivo é evitar interrogatórios desnecessários.

## Se plataforma e preferência já estiverem claras

**Não faça perguntas adicionais.**

Confirme brevemente a interpretação e implemente.

Exemplo:

```text
Entendido:
- plataforma: MOBILE
- preferência: modoGestaoMobile
- valores: CATALOGO, PESSOAS, FINANCEIRO, GERAL
```

Depois prossiga com análise e implementação.

## Se a plataforma não estiver clara

Pergunte apenas:

```text
Essa preferência é para MOBILE, WEB ou AMBOS?
```

## Se o que deve ser persistido não estiver claro

Apresente uma proposta objetiva de contrato e peça confirmação.

Exemplo:

```text
Vou persistir:
modoGestaoMobile = CATALOGO | PESSOAS | FINANCEIRO | GERAL

Confirma?
```

Se o usuário descreveu a funcionalidade mas não deu um bom nome para o campo, proponha um nome consistente com o projeto.

Não exija que o usuário conheça DTOs, classes, providers, repositories, payloads ou detalhes de implementação.

Esses detalhes devem ser descobertos no repositório.

## Se plataforma e preferência estiverem faltando

Pergunte em uma única mensagem:

```text
Só preciso confirmar duas coisas:
1. É MOBILE, WEB ou AMBOS?
2. Qual preferência deve ser persistida e quais valores ela pode assumir?
```

Depois da confirmação, não continue pedindo decisões técnicas que possam ser resolvidas pela análise do código existente.

---

# Regra para MOBILE, WEB e AMBOS

## MOBILE

A preferência deve representar comportamento específico do aplicativo Mobile.

Quando fizer sentido, siga a convenção já existente de nomes terminados em:

```text
Mobile
```

Exemplo:

```text
modoGestaoMobile
```

Mas não renomeie uma preferência explicitamente definida pelo usuário.

## WEB

A preferência deve representar comportamento específico da aplicação Web.

Quando fizer sentido, siga a convenção já existente de nomes terminados em:

```text
Web
```

Exemplo:

```text
ocultarValoresFinanceirosWeb
```

Mas não renomeie uma preferência explicitamente definida pelo usuário.

Sempre prefira nomes que deixem explícito que a preferência pertence à versão
Web, como `algoWeb`, `filtrosWeb`, `modoXWeb`, `secaoInicialWeb`.

## AMBOS

Primeiro verifique a intenção descrita.

Se o comportamento deve ser independente por plataforma, prefira dois campos, seguindo o padrão existente:

```text
nomeDaPreferenciaMobile
nomeDaPreferenciaWeb
```

Se o usuário explicitamente quiser uma única configuração compartilhada entre Mobile e Web, use uma preferência única.

Não introduza automaticamente sincronização cruzada entre Mobile e Web se isso não estiver implícito na solicitação.

## Regra de nomenclatura obrigatória

Ao propor ou criar um nome de preferência, use um nome que deixe claro a qual
plataforma ela pertence:

```text
...Web
...Mobile
```

Exemplos corretos:

```text
catalogoReservasFiltrosWeb
modoGestaoMobile
ocultarValoresFinanceirosWeb
```

Exemplos a evitar quando a preferência é específica por plataforma:

```text
catalogoReservasFiltros
modoGestao
preferenciaDeFiltro
```

Se o usuário disser apenas "salvar esse filtro", você deve deixar explícito na
sua interpretação se está falando de `Web`, `Mobile` ou `Ambos`.

---

# Etapa 1 — Inspecionar a implementação existente

Antes de editar código, localize no repositório:

- uso de `/api/eventos/atualizacoes-simples`;
- uso de `/private/api/eventos/atualizacoes-simples`;
- clients antigos ou divergentes de preferências, como rotas dedicadas de
  `dados-pessoais/preferencias`, para migrar/reapontar para o evento simples
  quando a tarefa for de preferências individuais;
- DTOs/models de `preferenciasIndividuaisDoUsuario`;
- persistência dessas preferências no backend;
- carregamento das preferências após login/inicialização;
- state management Flutter usado para preferências;
- repositories/services responsáveis por preferências;
- uso existente de `SharedPreferences` ou abstração equivalente;
- serialização/deserialização;
- enums de preferências;
- testes existentes relacionados a preferências.

Não crie arquitetura paralela sem antes entender o padrão atual.

Prioridade:

```text
reutilizar > estender > criar
```

---

# Etapa 2 — Definir o contrato da preferência

Com base no que foi confirmado pelo usuário, defina claramente:

```text
plataforma
campo
tipo
valores válidos
fallback
```

Exemplo:

```text
Plataforma: MOBILE
Campo: modoGestaoMobile
Tipo: enum
Valores:
- CATALOGO
- PESSOAS
- FINANCEIRO
- GERAL
Fallback: CATALOGO
```

Para boolean:

```text
Plataforma: WEB
Campo: ocultarValoresFinanceirosWeb
Tipo: boolean
Valores:
- true
- false
Fallback: comportamento atual
```

Nunca invente um fallback que altere o comportamento atual da aplicação.

Na ausência de preferência persistida, preserve o comportamento existente.

---

# Etapa 3 — Backend Java

O backend deve persistir a preferência dentro de:

```text
preferenciasIndividuaisDoUsuario
```

Localize a estrutura real e altere somente os pontos necessários.

Verifique, conforme a arquitetura existente:

- entidade ou document;
- DTO de entrada;
- DTO de saída;
- mapper;
- enum;
- service;
- repository;
- serialização/deserialização;
- persistência;
- evento de atualização simples;
- resposta que carrega as preferências do usuário.

Não presuma nomes de classes.

## Tipagem

Evite strings mágicas.

Para escolhas enumeradas, prefira enum se isso seguir o padrão do backend.

Exemplo:

```java
public enum ModoGestaoMobile {
    CATALOGO,
    PESSOAS,
    FINANCEIRO,
    GERAL
}
```

Para configurações binárias, use boolean quando apropriado.

Para outros tipos, mantenha a tipagem mais específica possível.

---

# Etapa 4 — Atualização pelo endpoint existente

A preferência deve ser atualizada através do mecanismo já existente:

```text
/private/api/eventos/atualizacoes-simples
```

Não criar novo endpoint apenas para uma nova preferência.

Antes de implementar, descubra como o endpoint trabalha:

- atualização parcial;
- merge;
- DTO de evento;
- campos opcionais;
- objeto completo;
- outro mecanismo existente.

## Regra crítica

Uma atualização de uma preferência **não pode sobrescrever outras preferências**.

Exemplo incorreto:

```text
usuário altera modoGestaoMobile
    ↓
cliente envia outros campos com valores default
    ↓
preferências antigas são apagadas
```

Evite esse comportamento.

Se o endpoint suporta PATCH lógico/atualização parcial, envie somente a preferência modificada.

Se o projeto possui um DTO/evento específico de atualização parcial, reutilize-o.

## Contrato recomendado do evento simples no SixApp

Quando não houver contrato mais específico já implementado para preferências, usar
o envelope padrão:

```json
{
  "tipo": "PREFERENCIAS_INDIVIDUAIS_DO_USUARIO",
  "origem": "sixapp-flutter",
  "recurso": "preferenciasIndividuaisDoUsuario",
  "acao": "ATUALIZAR_PARCIAL",
  "ocorridoEm": "2026-08-09T00:00:00.000Z",
  "payload": {
    "nomeDaPreferenciaWeb": "VALOR"
  }
}
```

Regras desse envelope:

- enviar somente as chaves alteradas dentro de `payload`;
- aceitar resposta assíncrona do backend, como `202 Accepted`, quando o endpoint
  processar evento fire-and-forget;
- garantir que o service backend do evento aplique merge em
  `preferenciasIndividuaisDoUsuario`, não apenas registre log do evento;
- manter compatibilidade com preferências existentes enviadas pelo mesmo client,
  como idioma, modo de exibição e ocultação de valores.

---

# Etapa 5 — Flutter

A tela não deve fazer HTTP diretamente.

Evite:

```dart
onTap: () async {
  await http.post(...);
}
```

O widget deve comunicar a mudança para a camada de estado/aplicação.

Use as abstrações reais já existentes, como:

```text
Provider
Notifier
Controller
Bloc
Cubit
Repository
Service
```

conforme o projeto.

Não introduza uma nova abordagem de gerenciamento de estado apenas para esta preferência.

---

# Etapa 6 — Resposta imediata da interface

A experiência deve ser otimista.

Fluxo esperado:

```text
Usuário altera opção
        ↓
UI muda imediatamente
        ↓
Estado Flutter muda
        ↓
Cache local é atualizado
        ↓
Atualização é enviada ao backend
```

Não bloquear a interface esperando a resposta HTTP.

Falha temporária de persistência remota não deve impedir o usuário de navegar ou alterar a opção.

Use o tratamento de erro já existente para preferências.

Não introduza Snackbar, diálogo ou mensagem agressiva se o projeto atualmente trata essas atualizações silenciosamente.

---

# Etapa 7 — Cache local

Persistir também localmente utilizando a abstração já adotada pelo projeto.

No Flutter, isso pode ser:

```text
SharedPreferences
```

ou outra camada já existente.

Não espalhar acesso direto a `SharedPreferences` por vários widgets.

Centralize o acesso na camada apropriada.

No SixApp Flutter, quando possível, centralize leitura/escrita do cache de
`preferenciasIndividuaisDoUsuario` em `UsuarioService` ou serviço equivalente,
usando o model completo de preferências para merge local. Widgets e telas devem
somente chamar o service/controller de aplicação.

A finalidade do cache local é permitir:

- restauração rápida;
- menor atraso visual;
- continuidade de experiência enquanto as preferências remotas são carregadas.

---

# Etapa 8 — Carregamento na inicialização

Esta etapa é obrigatória.

Não basta salvar a preferência no backend.

Localize o fluxo real de inicialização/autenticação que carrega:

```text
preferenciasIndividuaisDoUsuario
```

A nova preferência deve participar desse fluxo.

Quando a preferência for específica de uma tela, entenda "inicialização" também
como o momento em que a tela/fluxo é aberto novamente. Ou seja: ao abrir a tela,
você deve buscar/aplicar a preferência persistida e refletir isso na UI.

Quando o backend retornar um valor válido:

```text
backend
  ↓
modelo Flutter
  ↓
estado da aplicação
  ↓
UI
```

A interface correspondente deve ser inicializada com essa preferência.

Exemplo:

```json
{
  "preferenciasIndividuaisDoUsuario": {
    "modoGestaoMobile": "PESSOAS"
  }
}
```

Ao entrar novamente em Gestão Mobile, a tela deve abrir em:

```text
PESSOAS
```

---

# Etapa 9 — Regra de sincronização

A intenção arquitetural padrão é:

```text
BACKEND
= persistência durável da preferência

CACHE LOCAL
= resposta rápida

ESTADO FLUTTER
= estado corrente da sessão
```

Fluxo recomendado, salvo se o projeto já tiver regra diferente:

```text
1. Ler cache local para estado inicial rápido, quando aplicável.
2. Carregar preferências do backend.
3. Se o backend retornar valor válido, ele prevalece.
4. Atualizar o estado Flutter.
5. Sincronizar o cache local com o valor remoto.
```

Em forma resumida:

```text
backend válido -> prevalece -> sincroniza estado e cache
```

Se o SixApp já possuir uma estratégia consolidada para outras preferências, reutilize-a em vez de criar esta regra do zero.

---

# Etapa 10 — Compatibilidade retroativa

Toda nova preferência deve ser compatível com usuários que ainda não possuem o campo persistido.

Considere:

```text
campo ausente
null
valor legado
```

Não permitir:

- erro de serialização;
- NPE;
- tela quebrada;
- inicialização inválida.

Se a preferência não existir, preserve o comportamento atual da aplicação.

Exemplo:

```text
preferência válida
    ↓
usar preferência

preferência ausente
    ↓
usar fallback compatível com comportamento atual
```

Não faça migração em massa sem necessidade.

---

# Etapa 11 — Preferências enumeradas

Quando uma preferência possuir conjunto fechado de valores, garanta consistência entre backend e Flutter.

Exemplo:

Backend:

```text
CATALOGO
PESSOAS
FINANCEIRO
GERAL
```

Flutter pode usar enum idiomático:

```text
catalogo
pessoas
financeiro
geral
```

mas a serialização remota deve usar exatamente o contrato definido.

Centralize a conversão.

Não espalhe comparações de strings pelos widgets.

Para seletores cujo label pode vir do backend ou ser configurável por comércio,
como forma/tipo de pagamento, técnico, cliente, categoria ou status customizado,
persista o código técnico estável e não o label exibido. Exemplos:

```text
agendaFinanceiraTipoDePagamentoWeb = ["tipo1", "tipo2"]
```

ou, quando o contrato do domínio usar enum técnico:

```text
formaPagamentoPadraoWeb = PIX | BOLETO | CARTAO_CREDITO
```

Na UI, converta código técnico para label com os dados carregados do backend ou
com mapeador centralizado.

---

# Etapa 12 — Preferências booleanas

Para toggle/checkbox/switch, prefira contrato booleano quando semanticamente adequado.

Exemplo:

```json
"ocultarValoresFinanceirosWeb": true
```

Evite:

```json
"ocultarValoresFinanceirosWeb": "SIM"
```

a menos que um contrato legado já obrigue isso.

---

# Etapa 13 — Mudanças visuais

Esta skill trata de persistência de preferência.

Não altere design automaticamente.

Não alterar sem pedido explícito:

- AppBar;
- BottomNavigationBar;
- cards;
- cores;
- fontes;
- espaçamentos;
- ícones;
- animações;
- estrutura visual da tela.

A funcionalidade visual existente deve permanecer igual, exceto pelo comportamento necessário para refletir a preferência restaurada.

---

# Etapa 14 — Testes

Adicione ou atualize testes seguindo o padrão do projeto.

Quando aplicável, cobrir:

## Flutter

- serialização;
- deserialização;
- enum/conversão;
- payload do evento simples enviado pelo client reutilizável;
- atualização de estado;
- cache local;
- restauração da preferência;
- aplicação do valor retornado pelo backend;
- fallback;
- comportamento quando chamada remota falha;
- widget refletindo a preferência restaurada.

## Backend

- serialização;
- deserialização;
- enum;
- envelope do evento simples;
- atualização parcial;
- persistência;
- retorno em `preferenciasIndividuaisDoUsuario`;
- campo ausente;
- valor nulo;
- compatibilidade com registros antigos;
- preservação das outras preferências.
- compatibilidade com resposta assíncrona do endpoint de eventos, quando houver.

Não remover ou enfraquecer testes existentes.

---

# Critérios de aceite genéricos

Uma implementação de preferência só está concluída quando:

- [ ] a plataforma confirmada foi respeitada;
- [ ] o campo confirmado foi criado/reutilizado;
- [ ] os valores confirmados são suportados;
- [ ] a UI atualiza imediatamente;
- [ ] o estado Flutter é atualizado;
- [ ] o cache local é atualizado;
- [ ] o backend é atualizado;
- [ ] `/private/api/eventos/atualizacoes-simples` foi reutilizado;
- [ ] outras preferências não são sobrescritas;
- [ ] a preferência é retornada pelo backend;
- [ ] a preferência é carregada na inicialização/autenticação;
- [ ] ao abrir a tela/fluxo novamente, a UI busca/restaura a preferência;
- [ ] a tela restaura a escolha do usuário;
- [ ] usuários antigos continuam funcionando;
- [ ] não existe HTTP diretamente no widget;
- [ ] não existe duplicação desnecessária por opção;
- [ ] o comportamento visual atual foi preservado;
- [ ] testes relevantes foram executados.

---

# Saída esperada ao concluir uma tarefa

Ao final da implementação, informe de forma objetiva:

1. **Preferência implementada**
   ```text
   campo = valores
   ```

2. **Plataforma**
   ```text
   MOBILE | WEB | AMBOS
   ```

3. **Flutter**
   - arquivos alterados;
   - onde o estado é mantido;
   - onde o cache é persistido;
   - onde a preferência é restaurada.

4. **Backend**
   - arquivos alterados;
   - onde a preferência é persistida;
   - onde é retornada.

5. **Atualização remota**
   - payload efetivamente utilizado em `/private/api/eventos/atualizacoes-simples`;
   - confirmação de que a atualização não sobrescreve os demais campos.

6. **Inicialização**
   - como Backend → Flutter → UI/cache funciona.

7. **Compatibilidade**
   - fallback para usuários sem a preferência.

8. **Testes**
   - testes adicionados/alterados;
   - comandos executados;
   - resultado.

---

# Exemplo 1 — Mobile com enum

Pedido:

```text
Quando eu clicar em Catálogo, Pessoas, Financeiro ou Geral,
quero lembrar a última opção no mobile.
```

Se o campo ainda não foi informado, proponha:

```text
Plataforma: MOBILE

Preferência:
modoGestaoMobile =
CATALOGO | PESSOAS | FINANCEIRO | GERAL
```

Peça apenas a confirmação desse contrato.

Depois implemente todo o fluxo desta skill.

---

# Exemplo 2 — Web com boolean

Pedido:

```text
Na Web, quando o usuário marcar ocultar valores financeiros,
quero que isso fique salvo.
```

Interpretação:

```text
Plataforma: WEB
Campo: ocultarValoresFinanceirosWeb
Tipo: boolean
Valores: true | false
```

Se isso estiver claro, não faça perguntas técnicas adicionais.

Implemente:

```text
UI
↓
estado Flutter Web
↓
cache local
↓
/private/api/eventos/atualizacoes-simples
↓
preferenciasIndividuaisDoUsuario
```

e restaure na próxima inicialização.

---

# Exemplo 3 — Plataforma não informada

Pedido:

```text
Quero salvar a ordenação escolhida pelo usuário.
```

Pergunte somente:

```text
Essa preferência é para MOBILE, WEB ou AMBOS?
```

Se também não estiver claro o contrato, proponha algo como:

```text
ordenacaoProdutos[Mobile|Web] =
NOME_ASC | NOME_DESC | PRECO_ASC | PRECO_DESC
```

e peça confirmação.

---

# Exemplo 4 — Valor já definido

Pedido:

```text
No mobile, quando marcar modo compacto, salve
modoListaProdutosMobile = COMPACTO.
```

Não pergunte novamente o que já foi informado.

Confirme:

```text
Plataforma: MOBILE
Preferência: modoListaProdutosMobile = COMPACTO
```

e implemente.

---

# Restrições permanentes

- Não criar endpoint novo para cada preferência.
- Não salvar somente localmente.
- Não tratar cache local como persistência definitiva.
- Não colocar HTTP diretamente no widget.
- Não criar lógica duplicada para cada botão.
- Não sobrescrever preferências vizinhas.
- Não alterar UI fora do pedido.
- Não inventar valores sem confirmação quando o contrato não estiver claro.
- Não pedir ao usuário detalhes que podem ser descobertos no código.
- Não refatorar áreas fora do escopo.
- Não quebrar usuários que ainda não possuem a nova preferência.

---

# Princípio central

Sempre que o usuário disser:

```text
quero que essa escolha seja lembrada
```

pense no fluxo completo:

```text
INTERAÇÃO DO USUÁRIO
        ↓
ESTADO DA UI
        ↓
CACHE LOCAL
        ↓
PREFERÊNCIAS INDIVIDUAIS NO BACKEND
        ↓
CARREGAMENTO NO PRÓXIMO LOGIN/INICIALIZAÇÃO
        ↓
RESTAURAÇÃO DA UI
```

A implementação não está completa se qualquer uma dessas etapas necessárias estiver ausente.
