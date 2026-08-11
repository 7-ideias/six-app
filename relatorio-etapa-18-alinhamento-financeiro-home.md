# Relatório Etapa 18 - Alinhamento Financeiro da Home

## 1. Resumo executivo

A divergência financeira entre a Home "Meu dia no SixApp" e a Agenda Financeira foi corrigida no backend sem alterar o contrato JSON consumido pelo Flutter.

Antes desta etapa, o bloco financeiro do endpoint `GET /private/api/web/workspace/home` agregava apenas lançamentos persistidos diretamente em `OperacaoFinanceiraRepository`. A Agenda Financeira, por outro lado, usa `AgendaFinanceiraRecorrenciaConsultaService.consultarComOcorrenciasRecorrentes(...)` e expande ocorrências recorrentes/projetadas. Isso explicava o cenário autenticado em que a Agenda mostrava `2 lançamentos / BRL 1.100,00` para `Hoje / Receber`, enquanto a Home mostrava `0 contas / BRL 0,00`.

A solução escolhida foi mover a agregação financeira da Home para a mesma camada semântica da Agenda: `WorkspaceHomeService` agora delega o bloco financeiro para `AgendaFinanceiraRecorrenciaConsultaService.resumirWorkspaceHomeFinanceiro(...)`, que reutiliza a expansão de recorrências existente e agrega por `RECEBER`/`PAGAR`, hoje/vencidas.

## 2. Veredito

**ALINHADO COM RESSALVAS**

A regra backend está alinhada por código e testes automatizados, incluindo o cenário `650 + 450 = 1100`. A ressalva é operacional: o backend que estava em execução no ambiente local foi iniciado antes da alteração, e eu não reiniciei/matei o processo do usuário sem autorização explícita. A comparação autenticada final Home x Agenda deve ser repetida após restart do backend.

## 3. Branches e worktrees

Frontend:

```text
branch: feature/web-workspace-home-sidebar
```

O worktree já estava sujo por etapas anteriores, incluindo arquivos de navegação, Home, relatórios, screenshots e arquivos iOS adicionados. Nenhum reset, clean, stash ou descarte foi executado.

Backend:

```text
branch: feature/20260728-melhorias
```

O worktree também já estava sujo por etapas anteriores, incluindo arquivos do endpoint agregado da Home, alterações de estoque/assistência/regionalização e deletes já existentes de documentação. Nenhum reset, clean, stash ou descarte foi executado.

## 4. Divergência original

Caso observado no QA autenticado:

```text
Home
A receber hoje
BRL 0,00
0 contas

Agenda Financeira
Período: Hoje
Tipo: Receber
BRL 1.100,00
2 lançamentos
```

Os lançamentos visíveis na Agenda tinham valores:

```text
BRL 650,00
BRL 450,00
```

e vencimento operacional:

```text
10/08/2026
```

## 5. Investigação dos lançamentos reais

Não alterei dados reais. Também não fiz bypass de autenticação.

Foi possível confirmar a causa pelo código, mas não rastrear diretamente os IDs reais dos dois lançamentos no banco durante esta execução porque:

- o endpoint privado sem token retornou `401`, como esperado;
- a sessão autenticada estava no navegador real do usuário;
- o backend local em execução estava aberto antes da alteração;
- não reiniciei o processo Java do usuário sem autorização explícita.

O cenário real foi reproduzido em teste automatizado com duas ocorrências recorrentes de `BRL 650,00` e `BRL 450,00`, validando que a Home agora retorna `2 / 1100.00` com a mesma lógica da Agenda.

## 6. Semântica da Agenda Financeira

A Agenda Financeira usa:

```text
AgendaFinanceiraController
→ AgendaFinanceiraRecorrenciaConsultaService
→ consultarComOcorrenciasRecorrentes(...)
```

A rotina:

- identifica operações recorrentes por `recorrente`, `quantidadeParcelas` ou `frequenciaRecorrencia`;
- expande ocorrências no período consultado;
- usa vencimento calculado para cada ocorrência;
- separa `RECEBER` e `PAGAR`;
- trata `CANCELADO`/`CANCELADA` como não somável;
- trata quitados/finalizados como `RECEBIDO` ou `PAGO`;
- preserva `PARCIAL` como status aberto/parcial;
- usa o dia da empresa via `HorarioRegionalizacaoService`.

## 7. Semântica anterior da Home

A Home fazia agregação direta no repositório sobre lançamentos persistidos:

```text
WorkspaceHomeService
→ OperacaoFinanceiraRepository
→ queries por dataVencimento/tipo/status
```

Esse caminho não expandia ocorrências recorrentes. Portanto, uma cobrança que aparece na Agenda como ocorrência projetada de hoje podia não existir como linha persistida com vencimento de hoje e ficava fora da Home.

## 8. Causa raiz confirmada

A causa raiz foi a duplicidade de semântica:

```text
Agenda
→ ocorrências financeiras lógicas do período

Home
→ lançamentos persistidos do período
```

Quando o cenário dependia de recorrência/projeção, os resultados divergiam.

## 9. Recorrências

A Home agora reaproveita a mesma expansão de recorrências da Agenda. Não foi criada uma segunda engine de recorrência no `WorkspaceHomeService`.

A nova entrada pública no serviço da Agenda é:

```text
AgendaFinanceiraRecorrenciaConsultaService.resumirWorkspaceHomeFinanceiro(...)
```

Ela consulta candidatos financeiros do tenant e usa a expansão já existente para montar os quatro resumos:

- `receivableToday`;
- `payableToday`;
- `overdueReceivable`;
- `overduePayable`.

## 10. Ocorrências projetadas

Ocorrências projetadas são geradas pela mesma rotina interna que já alimenta a Agenda. A Home não materializa dados e não altera registros.

Para `Hoje`, entram ocorrências com:

```text
dataVencimento == hojeDaEmpresa
status aberto/parcial
tipo RECEBER ou PAGAR
valor aberto > 0
```

Para vencidas, entram ocorrências com:

```text
dataVencimento < hojeDaEmpresa
status aberto/parcial
valor aberto > 0
```

## 11. Liquidação

Lançamentos quitados não entram no resumo:

- `statusQuitada == true`;
- ou `dataQuitacao != null`;
- ou status textual de quitado/liquidado/pago/recebido.

Para liquidações parciais em payload, a Home usa o valor restante quando disponível.

## 12. Parcial

`PARCIAL` continua elegível como aberto/parcial.

O valor usado no resumo é o valor aberto:

1. `agendaFinanceiraValorRestante`, se existir no payload;
2. senão, `valorTotalOperacao - soma(agendaFinanceiraLiquidacoes.valorLiquidado)`;
3. senão, valor total normalizado.

Valores monetários são tratados como `BigDecimal`, com normalização para duas casas e sem conversão via `double`.

## 13. Cancelamento

Cancelados não entram:

- query candidata já exclui tokens como `CANCELADA` e `CANCELADO`;
- a lógica de Agenda ainda aplica `deveSomar(...)`, que exclui `CANCELADO`.

## 14. Vencidas

Vencidas são resumidas como:

```text
dataVencimento < hojeDaEmpresa
AND status aberto/parcial
AND valor aberto > 0
```

Inclui ocorrências recorrentes geradas antes de hoje. Não limita vencidas ao período visual "Hoje".

## 15. Timezone

O endpoint continua usando:

```text
HorarioRegionalizacaoService.hojeDaEmpresa(idUnicoDaEmpresa)
```

O cálculo de "hoje" permanece baseado na empresa, não no timezone do servidor nem no navegador.

## 16. Estratégia arquitetural escolhida

A estratégia foi centralizar a semântica financeira da Home na camada já usada pela Agenda:

```text
WorkspaceHomeService
→ AgendaFinanceiraRecorrenciaConsultaService.resumirWorkspaceHomeFinanceiro(...)
→ expansão recorrente existente
→ WorkspaceHomeFinancialResponse
```

Assim, a Home continua sendo agregada e eficiente o suficiente para V1, mas deixa de ter regra financeira paralela.

## 17. Reutilização da lógica da Agenda

Reutilização real implementada:

- `expandirOperacaoNoPeriodo(...)`;
- `resolverInicioRecorrencia(...)`;
- `extrairDataVencimento(...)`;
- `mapearStatusLancamento(...)`;
- `deveSomar(...)`;
- `isStatusEmAbertoOuParcial(...)`;
- mapeamento de tipo financeiro.

Não foi copiada uma segunda regra de recorrência para a Home.

## 18. Performance

A Home não voltou a usar `findAll()` global.

Foi adicionada query candidata em `OperacaoFinanceiraRepository` filtrando por:

- `idUnicoDaEmpresa`;
- não quitado;
- sem `dataQuitacao`;
- status não cancelado/finalizado/quitado/liquidado/pago/recebido;
- vencimento antes do fim de hoje ou operação recorrente/parcelada.

Depois disso, a expansão acontece em memória apenas sobre candidatos da empresa.

Risco remanescente: uma empresa com muitas recorrências abertas antigas pode gerar um intervalo grande para expansão. Para escala alta, a solução mais robusta continua sendo materialização/projeção de ocorrências financeiras ou índice/consulta específica para recorrências.

## 19. Queries

Nova query principal:

```text
buscarCandidatasWorkspaceHomeFinanceiro(idUnicoDaEmpresa, fimExclusivo)
```

Ela busca somente candidatos que podem impactar o resumo até hoje. Os métodos antigos de agregação direta da Home foram removidos para evitar coexistência de duas semânticas financeiras.

## 20. Índices

Não foi criado índice novo nesta etapa.

Índices já existentes observados no domínio financeiro dão suporte parcial a:

- empresa + data de vencimento;
- empresa + status;
- empresa + data de operação;
- empresa + origem;
- empresa + forma de pagamento.

Se a base crescer muito em recorrências abertas, pode ser necessário avaliar índice composto envolvendo:

```text
idUnicoDaEmpresa
statusQuitada
dataQuitacao
dataVencimento
recorrente
quantidadeParcelas
frequenciaRecorrencia
```

Não implementei índice sem medição.

## 21. Arquivos backend criados

Criado nesta etapa:

```text
src/test/java/br/com/seteideias/sixback/service/AgendaFinanceiraRecorrenciaConsultaServiceTest.java
```

Já existiam como arquivos não rastreados de etapas anteriores:

```text
src/main/java/br/com/seteideias/sixback/controller/workspace/
src/main/java/br/com/seteideias/sixback/dto/workspace/
src/main/java/br/com/seteideias/sixback/service/WorkspaceHomeService.java
src/test/java/br/com/seteideias/sixback/service/WorkspaceHomeServiceTest.java
```

## 22. Arquivos backend alterados

Alterados nesta etapa:

```text
src/main/java/br/com/seteideias/sixback/repository/caixa/OperacaoFinanceiraRepository.java
src/main/java/br/com/seteideias/sixback/service/AgendaFinanceiraRecorrenciaConsultaService.java
src/main/java/br/com/seteideias/sixback/service/WorkspaceHomeService.java
src/test/java/br/com/seteideias/sixback/service/WorkspaceHomeServiceTest.java
src/test/java/br/com/seteideias/sixback/service/AgendaFinanceiraRecorrenciaConsultaServiceTest.java
```

Também foi removida a projeção transitória não usada:

```text
src/main/java/br/com/seteideias/sixback/repository/caixa/WorkspaceHomeFinancialAggregation.java
```

## 23. Arquivos frontend alterados

Nenhum código Flutter foi alterado nesta etapa.

Arquivo criado no frontend apenas como documentação obrigatória:

```text
relatorio-etapa-18-alinhamento-financeiro-home.md
```

## 24. Contrato final

Contrato Flutter preservado.

O bloco continua:

```json
{
  "financial": {
    "available": true,
    "receivableToday": { "count": 0, "amount": 0 },
    "payableToday": { "count": 0, "amount": 0 },
    "overdueReceivable": { "count": 0, "amount": 0 },
    "overduePayable": { "count": 0, "amount": 0 }
  }
}
```

Não houve breaking change no model, api client, provider ou tela.

## 25. Compatibilidade com Etapa 15

Compatível.

O endpoint continua agregado, por empresa, com `date`, `timeZone`, `cash`, `technicalServices`, `financial` e `stock`.

A diferença é apenas semântica interna do cálculo financeiro.

## 26. Permissões

Preservado:

```text
financial.available = false
```

quando o usuário não possui permissão financeira.

Teste mantido:

```text
colaboradorSemFinanceiroNaoRecebeValoresFinanceiros
```

Ele valida que, sem permissão financeira, o `AgendaFinanceiraRecorrenciaConsultaService` não é chamado.

## 27. Testes de recorrência

Criados testes cobrindo:

- recorrente `RECEBER` hoje;
- recorrente `PAGAR` hoje;
- recorrente `RECEBER` vencida;
- recorrente `PAGAR` vencida;
- múltiplas ocorrências no cenário `650 + 450 = 1100`.

## 28. Testes de duplicidade

Teste:

```text
parcelaBaseRecorrentePersistidaContaUmaVez
```

Valida que uma ocorrência base recorrente persistida para hoje é contabilizada uma vez.

## 29. Testes de operações simples

Teste:

```text
operacaoSimplesNaoRecorrenteContinuaFuncionando
```

Valida que operação simples não recorrente continua entrando corretamente em `receivableToday` ou vencidas.

## 30. Testes WorkspaceHomeService

Executado:

```bash
./mvnw -q -Dtest=WorkspaceHomeServiceTest,AgendaFinanceiraRecorrenciaConsultaServiceTest test
```

Resultado:

```text
WorkspaceHomeServiceTest: 2 testes, 0 falhas
AgendaFinanceiraRecorrenciaConsultaServiceTest: 10 testes, 0 falhas
```

## 31. Testes Agenda

O novo `AgendaFinanceiraRecorrenciaConsultaServiceTest` cobre diretamente a camada da Agenda.

Inclui comparação automática:

```text
homeEAgendaUsamMesmaSemanticaParaHojeReceber
```

Esse teste usa os mesmos dados, mesma empresa e mesma data para consultar:

```text
AgendaFinanceiraRecorrenciaConsultaService.consultarComOcorrenciasRecorrentes(...)
AgendaFinanceiraRecorrenciaConsultaService.resumirWorkspaceHomeFinanceiro(...)
```

e valida equivalência do total de `RECEBER` hoje.

## 32. Compile backend

Executado:

```bash
./mvnw -q -DskipTests compile
```

Resultado:

```text
SUCCESS
```

## 33. QA autenticado

Não foi concluído pós-restart nesta etapa.

Evidências do ambiente:

- frontend rodando em `http://localhost:39441/app`;
- frontend apontando para `http://localhost:8082`;
- backend Java ativo em `8082`, iniciado antes desta alteração;
- `curl` sem token para `/private/api/web/workspace/home` retornou `401`, como esperado.

Não forcei restart do processo Java aberto pelo usuário e não tentei extrair/injetar token da sessão do navegador.

## 34. Comparação Home x Agenda - receber hoje

Automatizada:

```text
Agenda: 2 lançamentos / 1100.00
Home antes: 0 lançamentos / 0.00 quando dependia de ocorrência projetada
Home depois: 2 lançamentos / 1100.00
```

QA real pendente após restart backend.

## 35. Comparação Home x Agenda - pagar hoje

Automatizada:

```text
Recorrente PAGAR hoje
Home depois: 1 lançamento / 120.00
```

A mesma expansão da Agenda é usada.

## 36. Comparação Home x Agenda - vencidas

Automatizada:

```text
Recorrente RECEBER vencida
Home depois: 2 lançamentos / 160.00

Recorrente PAGAR vencida
Home depois: 2 lançamentos / 110.00
```

## 37. Reteste do Caixa

Pendente de restart/QA autenticado.

Nenhuma alteração de layout ou contrato do Caixa foi feita nesta etapa. A correção anterior de `openedAt` permanece no contrato, mas precisa ser observada novamente na Home real após reiniciar o backend.

## 38. Testes Flutter

Executados:

```bash
flutter test \
  test/providers/workspace_home_provider_test.dart \
  test/presentation/screens/workspace_home_web_test.dart
```

Resultado:

```text
11 testes passaram
```

Executada também a suíte direcionada:

```bash
flutter test \
  test/presentation/components/web_dashboard_widgets_test.dart \
  test/presentation/navigation/web_navigation_registry_test.dart \
  test/presentation/navigation/web_navigation_destination_resolver_test.dart \
  test/presentation/navigation/pagina_principal_web_navigation_actions_test.dart \
  test/presentation/navigation/web_navigation_destination_mapper_test.dart \
  test/presentation/navigation/web_navigation_permission_adapter_test.dart \
  test/presentation/layouts/authenticated_web_shell_test.dart \
  test/providers/workspace_home_provider_test.dart \
  test/presentation/screens/workspace_home_web_test.dart
```

Resultado:

```text
48 testes passaram
```

## 39. Analyzer Flutter

Executado:

```bash
flutter analyze
```

Resultado:

```text
716 issues
```

Baseline histórico preservado.

## 40. Build Web

Executado com:

```text
_useWebShellNavigation = true
_useWorkspaceHome = true
```

Comando:

```bash
flutter build web
```

Resultado:

```text
SUCCESS
```

Avisos históricos de Wasm do pacote `image` permaneceram, sem relação com esta etapa.

## 41. Regressões

Nenhuma regressão automatizada encontrada.

Não houve alteração de contrato Flutter, não houve alteração visual da Home e não houve alteração Mobile.

## 42. Riscos remanescentes

Riscos:

- QA autenticado real pós-restart ainda pendente;
- empresas com grande volume de recorrências antigas abertas podem exigir otimização futura;
- a Agenda operacional ainda possui caminho legado com `findAll()` em `consultarComOcorrenciasRecorrentes(...)`; a Home não usa esse caminho, mas a Agenda pode merecer otimização separada;
- valores parciais dependem das chaves de payload já usadas pela Agenda Web quando não houver campo persistido dedicado.

## 43. Pendências

Pendências objetivas:

1. Reiniciar backend local para carregar a nova classe.
2. Recarregar o Web app autenticado.
3. Comparar novamente Home x Agenda para `Hoje / Receber`, `Hoje / Pagar` e vencidas com dados reais.
4. Retestar visualmente o card de Caixa com abertura em data anterior.

## 44. Desvios

Desvios em relação ao prompt:

- a validação autenticada real pós-restart não foi executada porque o backend em `8082` estava rodando antes da alteração e eu não reiniciei/matei o processo do usuário sem autorização;
- os dois lançamentos reais não foram identificados por ID no banco, pois o acesso direto ao endpoint privado sem token retornou `401` e não foi feito contorno de autenticação.

Não houve desvio de implementação: a correção foi feita no backend e o contrato frontend foi preservado.

## 45. A Home está pronta para novo QA final?

Sim.

A divergência de regra foi corrigida e coberta por testes. A Home está pronta para novo QA final autenticado após restart do backend.

## 46. Próxima etapa recomendada

Executar QA final da Home com backend reiniciado, focando:

- Home x Agenda em `Receber hoje`;
- Home x Agenda em `Pagar hoje`;
- Home x Agenda em vencidas;
- card de Caixa com abertura em outro dia;
- build e analyzer finais.

Se a comparação real confirmar os testes, a próxima decisão pode ser retirar o `DashboardInicioWeb` antigo ou manter apenas por fallback temporário.

## Tabela obrigatória de equivalência

| Cenário | Agenda | Home antes | Home depois | Igual? |
| ------- | -----: | ---------: | ----------: | ------ |
| Receber hoje | 2 / 1100.00 no cenário QA automatizado | 0 / 0.00 quando dependia de recorrência projetada | 2 / 1100.00 | Sim em teste; QA real pendente |
| Pagar hoje | 1 / 120.00 no teste recorrente | 0 / 0.00 quando dependia de recorrência projetada | 1 / 120.00 | Sim em teste |
| Receber vencido | 2 / 160.00 no teste recorrente | 0 / 0.00 quando dependia de recorrência projetada | 2 / 160.00 | Sim em teste |
| Pagar vencido | 2 / 110.00 no teste recorrente | 0 / 0.00 quando dependia de recorrência projetada | 2 / 110.00 | Sim em teste |

## Tabela de recorrências

| Cenário | Deve contar? | Contou? | Teste |
| ------- | ------------ | ------- | ----- |
| Recorrente hoje | Sim, se aberto/parcial e vence hoje | Sim | `recorrenteHojeEntraEmReceberHoje`, `recorrentePagarHojeEntraEmPagarHoje` |
| Recorrente vencida | Sim, se aberto/parcial e vence antes de hoje | Sim | `recorrenteVencidaEntraEmVencidas`, `recorrentePagarVencidaEntraEmPagarVencidas` |
| Quitada | Não | Não | `quitadaCanceladaEForaDoPeriodoNaoEntram` |
| Cancelada | Não | Não | `quitadaCanceladaEForaDoPeriodoNaoEntram` |
| Fora do período | Não | Não | `quitadaCanceladaEForaDoPeriodoNaoEntram` |
| Já materializada | Sim, uma vez | Sim | `parcelaBaseRecorrentePersistidaContaUmaVez` |
| Não recorrente | Sim, se aberto/parcial e dentro da regra de data | Sim | `operacaoSimplesNaoRecorrenteContinuaFuncionando` |
