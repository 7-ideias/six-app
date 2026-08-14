# Proposta de Navegação Web SixApp

Relatório produzido em 10 de agosto de 2026.

## 1. Resumo executivo

A Sidebar V1 deve reduzir a navegação global para áreas persistentes, não ações. A recomendação é ter 7 áreas visíveis inicialmente:

```text
Início
Atendimento
Catálogo
Pessoas
Caixa
Financeiro
Configurações
```

`Relatórios` deve ficar reservado, mas oculto na V1 até existir um hub real. Hoje o grupo em `TopNavigationBarWeb` apenas chama `_mostrarPreparacao()`.

Evidências centrais:

- `TopNavigationBarWeb._itemsEfetivos()` define a árvore efetiva: `lib/top_navigation_bar_web.dart`.
- `PaginaPrincipalWeb` controla módulos internos por `ModuloCentralPDV`: `lib/pagina_principal_web.dart`.
- `PaginaPrincipalWeb` usa `TopNavigationBarWeb` como `appBar`: `lib/pagina_principal_web.dart`.
- permissões disponíveis vêm de `ColaboradorAutorizacoesProvider`: `lib/providers/colaborador_autorizacoes_provider.dart`.

## 2. Problemas da navegação atual

O menu atual mistura destinos, ações, placeholders, duplicidades e itens legados.

Problemas técnicos:

- `TopNavigationBarWeb` não é só visual: ele abre overlays e chama telas diretamente.
- Vários módulos não têm rota própria, apenas callback, estado interno ou dialog.
- O grupo `Caixa` inteiro é preparatório, mas existe uma tela real `OperacoesCaixaWebPage` acessível por `Financeiro > Operações de Caixa`.
- `Relatórios` é totalmente preparatório no menu.
- `Configurações` mistura telas reais com páginas genéricas vazias.
- Permissões existem, mas o menu Web não as aplica de forma centralizada.
- `SingleChildScrollView` horizontal evita overflow, mas não resolve descoberta nem escalabilidade.

## 3. Critérios utilizados

Critério principal:

```text
Sidebar = áreas e destinos persistentes.
Tela/Home = ações operacionais e atalhos contextuais.
```

Classificação usada:

- `DESTINO`: área ou página persistente.
- `AÇÃO`: inicia um fluxo, mas não deveria ser item global.
- `CONFIGURAÇÃO`: pertence a uma central de configurações.
- `RELATÓRIO`: deve ficar em hub de relatórios, não espalhado.
- `DUPLICIDADE`: sobreposição semântica ou técnica.
- `LEGADO`: item mantido por compatibilidade interna.
- `PREPARATÓRIO`: item sem tela funcional no menu atual.
- `OUTRO`: perfil, sessão, usuário ou suporte.

## 4. Classificação dos itens atuais

Resumo por grupo atual:

| Grupo atual | Classificação dominante | Diagnóstico |
| --- | --- | --- |
| Atendimento | misto | Tem destinos reais, ações e duplicidades. |
| Catálogo | destino | É o grupo mais coerente hoje. |
| Pessoas | destino + outro + preparatório | Clientes/colaboradores são reais; perfil deve ir para Header; fornecedores ainda está em roadmap. |
| Caixa | ação/preparatório | Tudo no grupo atual chama `_mostrarPreparacao()`. |
| Financeiro | destino + preparatório | Agenda e Operações de Caixa são reais; demais itens são preparatórios. |
| Relatórios | relatório/preparatório | Todos os itens atuais são snackbar de preparação. |
| Configurações | configuração mista | Algumas seções reais, outras genéricas/vazias. |
| Legado | legado | Deve sair da navegação visível. |

A classificação item a item está consolidada na matriz da seção 5.

## 5. Matriz de migração

| Item atual | Grupo atual | Tipo | Tela real existe? | Destino proposto | Grupo futuro | Sidebar? | Ação contextual? | Permissão | Decisão |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PDV - Frente de Caixa | Atendimento | DESTINO | Sim, via `PaginaPrincipalWeb._iniciarVenda()` | Frente de caixa | Atendimento | Sim | Sim, `Nova venda` | `podeFazerVenda` | MOVER |
| Atendimento técnico | Atendimento | AÇÃO | Sim, `AtendimentosTecnicosWebPage` | Novo atendimento | Atendimento | Não | Sim | `podeLancarAssistenciaTecnica` | REMOVER DA NAVEGAÇÃO |
| Atendimentos criados | Atendimento | DESTINO | Sim, `AtendimentosTecnicosListaWebPage` | Assistências técnicas | Atendimento | Sim | Não | `podeLancarAssistenciaTecnica` | MOVER |
| Novo orçamento | Atendimento | AÇÃO/PREPARATÓRIO | Parcial, `OrcamentoWeb` existe, menu não abre | Novo orçamento | Atendimento | Não | Sim | Sem permissão específica; provável `podeFazerVenda` ou `podeLancarAssistenciaTecnica` | OCULTAR ATÉ IMPLEMENTAR |
| Nova assistência técnica | Atendimento | AÇÃO/DUPLICIDADE | Sim, mesma abertura de `Atendimento técnico` | Novo atendimento | Atendimento | Não | Sim | `podeLancarAssistenciaTecnica` | REMOVER DA NAVEGAÇÃO |
| Vendas | Atendimento | DUPLICIDADE/PREPARATÓRIO | Não pelo menu atual | Frente de caixa / vendas | Atendimento | Não como item separado | Sim | `podeFazerVenda` | AGRUPAR |
| Orçamentos | Atendimento | PREPARATÓRIO | Parcial | Orçamentos | Atendimento | Não na V1 | Sim | Sem permissão específica | OCULTAR ATÉ IMPLEMENTAR |
| Assistências técnicas | Atendimento | DUPLICIDADE | Sim, mesma abertura de `Atendimentos criados` | Assistências técnicas | Atendimento | Sim | Não | `podeLancarAssistenciaTecnica` | AGRUPAR |
| Produtos | Catálogo | DESTINO | Sim, `ProdutoDashboardWebPage` | Produtos | Catálogo | Sim | `Novo produto` dentro da tela | `podeCadastrarProduto`/`podeEditarProduto` | MANTER |
| Serviços | Catálogo | DESTINO | Sim, `ServicoDashboardWebPage` | Serviços | Catálogo | Sim | `Novo serviço` dentro da tela | `podeCadastrarProduto`/`podeEditarProduto` | MANTER |
| Categorias | Catálogo | DESTINO | Sim, `CategoriasProdutosServicosWebPage` | Categorias | Catálogo | Sim | `Nova categoria` dentro da tela | `podeAcessarCatalogo` | MANTER |
| Estoque | Catálogo | DESTINO | Sim, `EstoqueDashboardWebPage` | Estoque | Catálogo | Sim | Entrada/saída/ajuste dentro da tela | `podeVerEstoqueDeProduto` | MANTER |
| Meu Perfil | Pessoas | OUTRO | Sim, `showMeuPerfilWebDialog()` | Menu do usuário | Header | Não | Sim | autenticado | MOVER |
| Clientes | Pessoas | DESTINO | Sim, `ClientesUsuarioListPage` | Clientes | Pessoas | Sim | `Novo cliente` dentro da tela | `podeEditarCliente` | MANTER |
| Colaboradores | Pessoas | DESTINO | Sim, `ColaboradoresUsuarioListPage` | Colaboradores | Pessoas | Sim | `Novo colaborador` dentro da tela | Sem getter específico; usar ADMIN/permissão futura | MANTER |
| Fornecedores | Pessoas | PREPARATÓRIO | Parcial, `FornecedoresWebPage` é roadmap | Fornecedores | Pessoas | Não na V1 | Futuro | Sem permissão específica | OCULTAR ATÉ IMPLEMENTAR |
| Desempenho | Pessoas | DESTINO/RELATÓRIO | Sim, `DesempenhoColaboradorWebPage` | Desempenho | Pessoas | Sim | Filtros internos | `podeGerarRelatorio` | MOVER |
| Abrir caixa | Caixa | AÇÃO/PREPARATÓRIO | Sim dentro de `OperacoesCaixaWebPage`, mas menu atual não abre | Abrir caixa | Caixa | Não | Sim | `objLancamentosFinanceirosPode.podeReceberNoCaixa` | REMOVER DA NAVEGAÇÃO |
| Fechar caixa | Caixa | AÇÃO/PREPARATÓRIO | Sim dentro de `OperacoesCaixaWebPage`, mas menu atual não abre | Fechar caixa | Caixa | Não | Sim | `podeReceberNoCaixa` | REMOVER DA NAVEGAÇÃO |
| Movimentações | Caixa | DESTINO/PREPARATÓRIO | Sim dentro de `OperacoesCaixaWebPage` | Operação de caixa | Caixa | Sim como parte de Caixa | Sim | `podeAcessarFinanceiro` | AGRUPAR |
| Suprimento | Caixa | AÇÃO/PREPARATÓRIO | Sim dentro de operação de caixa | Suprimento | Caixa | Não | Sim | `podeReceberNoCaixa` | REMOVER DA NAVEGAÇÃO |
| Sangria | Caixa | AÇÃO/PREPARATÓRIO | Sim dentro de operação de caixa | Sangria | Caixa | Não | Sim | `podeReceberNoCaixa` | REMOVER DA NAVEGAÇÃO |
| Retirada para despesa | Caixa | AÇÃO/PREPARATÓRIO | Parcial dentro de movimentos | Retirada para despesa | Caixa | Não | Sim | `podeReceberNoCaixa` | REMOVER DA NAVEGAÇÃO |
| Ajustes | Caixa | AÇÃO/PREPARATÓRIO | Parcial dentro de movimentos | Ajuste de caixa | Caixa | Não | Sim | `podeReceberNoCaixa` | REMOVER DA NAVEGAÇÃO |
| Resumo do caixa | Caixa | DESTINO/PREPARATÓRIO | Sim dentro de `OperacoesCaixaWebPage` | Operação de caixa | Caixa | Sim como parte de Caixa | Não | `podeAcessarFinanceiro` | AGRUPAR |
| Contas a receber | Financeiro | PREPARATÓRIO | Parcial via `AgendaFinanceiraWeb`/`VendasAReceberWebWidget` | Filtro em Agenda financeira | Financeiro | Não na V1 | Sim | `podeAcessarFinanceiro` | AGRUPAR |
| Contas a pagar | Financeiro | PREPARATÓRIO | Parcial via `AgendaFinanceiraWeb` | Filtro em Agenda financeira | Financeiro | Não na V1 | Sim | `podeAcessarFinanceiro` | AGRUPAR |
| Recebimentos futuros | Financeiro | PREPARATÓRIO | Parcial via Agenda | Filtro em Agenda financeira | Financeiro | Não | Sim | `podeAcessarFinanceiro` | AGRUPAR |
| Fiado | Financeiro | PREPARATÓRIO | Não como tela dedicada | Futuro recurso financeiro | Financeiro | Não | Futuro | Sem permissão específica | OCULTAR ATÉ IMPLEMENTAR |
| Crediário | Financeiro | PREPARATÓRIO | Não como tela dedicada | Futuro recurso financeiro | Financeiro | Não | Futuro | Sem permissão específica | OCULTAR ATÉ IMPLEMENTAR |
| Agenda financeira | Financeiro | DESTINO | Sim, `AgendaFinanceiraWeb` | Agenda financeira | Financeiro | Sim | Receber/pagar dentro da tela | `podeAcessarFinanceiro` | MANTER |
| Operações de Caixa | Financeiro | DESTINO/DUPLICIDADE | Sim, `OperacoesCaixaWebPage` | Caixa | Caixa | Sim, mas no grupo Caixa | Sim | `podeAcessarFinanceiro` | MOVER |
| Relatório de Vendas | Relatórios | RELATÓRIO/PREPARATÓRIO | Não pelo menu atual | Hub de relatórios | Relatórios | Não na V1 | Futuro | `podeGerarRelatorio` | OCULTAR ATÉ IMPLEMENTAR |
| Relatório de Assistências | Relatórios | RELATÓRIO/PREPARATÓRIO | Não pelo menu atual | Hub de relatórios | Relatórios | Não na V1 | Futuro | `podeGerarRelatorio` | OCULTAR ATÉ IMPLEMENTAR |
| Relatório de Caixa | Relatórios | RELATÓRIO/PREPARATÓRIO | Não pelo menu atual | Hub de relatórios | Relatórios | Não na V1 | Futuro | `podeGerarRelatorio` | OCULTAR ATÉ IMPLEMENTAR |
| Relatório Financeiro | Relatórios | RELATÓRIO/PREPARATÓRIO | Não pelo menu atual | Hub de relatórios | Relatórios | Não na V1 | Futuro | `podeGerarRelatorio` | OCULTAR ATÉ IMPLEMENTAR |
| Relatório de Produtos | Relatórios | RELATÓRIO/PREPARATÓRIO | Parcial: PDF existe na lista de produtos | Relatório contextual em Produtos | Catálogo/Relatórios | Não | Sim | `podeGerarRelatorio` + catálogo | REMOVER DA NAVEGAÇÃO |
| Relatório de Clientes | Relatórios | RELATÓRIO/PREPARATÓRIO | Não pelo menu atual | Hub de relatórios | Relatórios | Não na V1 | Futuro | `podeGerarRelatorio` | OCULTAR ATÉ IMPLEMENTAR |
| Empresa | Configurações | CONFIGURAÇÃO | Sim, `EmpresaConfiguracaoForm` | Central de configurações | Configurações | Não como subitem global | Interno | ADMIN ou permissão futura | AGRUPAR |
| Cores e Fontes | Configurações | CONFIGURAÇÃO | Sim, `CoresFontesWebPage` | Central de configurações | Configurações | Não como subitem global | Interno | ADMIN ou permissão futura | AGRUPAR |
| Usuários e permissões | Configurações | CONFIGURAÇÃO/PREPARATÓRIO | Parcial; menu abre seção genérica, colaboradores existe em Pessoas | Central de configurações | Configurações | Não como subitem global | Interno | ADMIN; falta getter específico | OCULTAR ATÉ IMPLEMENTAR |
| Regionalização | Configurações | CONFIGURAÇÃO | Sim, `RegionalizacaoConfiguracaoContent` | Central de configurações | Configurações | Não como subitem global | Interno | ADMIN ou permissão futura | AGRUPAR |
| Formas de recebimento | Configurações | CONFIGURAÇÃO | Sim, `FormasRecebimentoConfiguracaoContent` | Central de configurações | Configurações | Não como subitem global | Interno | ADMIN/financeiro | AGRUPAR |
| Regras operacionais | Configurações | CONFIGURAÇÃO | Sim, `RegrasOperacionaisConfiguracaoContent` | Central de configurações | Configurações | Não como subitem global | Interno | ADMIN | AGRUPAR |
| Notificações | Configurações | CONFIGURAÇÃO/PREPARATÓRIO | Não; cai em `_buildBlankContent()` | Central de configurações futura | Configurações | Não | Futuro | ADMIN ou permissão futura | OCULTAR ATÉ IMPLEMENTAR |
| Modelos de PDF | Configurações | CONFIGURAÇÃO/PREPARATÓRIO | Não; cai em `_buildBlankContent()` | Central de configurações futura | Configurações | Não | Futuro | ADMIN ou permissão futura | OCULTAR ATÉ IMPLEMENTAR |
| Integrações | Configurações | CONFIGURAÇÃO/PREPARATÓRIO | Não; cai em `_buildBlankContent()` | Central de configurações futura | Configurações | Não | Futuro | ADMIN ou permissão futura | OCULTAR ATÉ IMPLEMENTAR |
| Categorias | Legado | LEGADO/DUPLICIDADE | Sim | Categorias | Catálogo | Não pelo grupo Legado | Não | `podeAcessarCatalogo` | LEGADO INTERNO |
| Preferências do Six | Legado | LEGADO/CONFIGURAÇÃO | Sim, `ConfiguracoesSixWebPage`, mas com mocks | Central de configurações | Configurações | Não pelo grupo Legado | Interno | autenticado/ADMIN conforme seção | LEGADO INTERNO |

## 6. Duplicidades encontradas

Atendimento técnico:

- `Atendimento técnico` e `Nova assistência técnica` chamam `_abrirAtendimentoTecnico()`.
- `Atendimentos criados` e `Assistências técnicas` chamam `_abrirAtendimentosCriados()`.
- Nome recomendado para destino: `Assistências técnicas`.
- Nome recomendado para ação: `Novo atendimento`.

Vendas:

- `PDV - Frente de Caixa` é o fluxo real.
- `Vendas` no menu atual cai em `_mostrarPreparacao()`.
- Nome recomendado: `Frente de caixa`.
- `Nova venda` deve ser ação rápida, não item da Sidebar.

Orçamentos:

- `Novo orçamento` e `Orçamentos` são preparatórios no menu efetivo.
- Existe `OrcamentoWeb` em `ModuloCentralPDV.orcamento`, mas não como destino claro do novo menu.
- Recomendação: não colocar `Orçamentos` na Sidebar V1 até existir destino persistente de consulta/gestão.

Caixa:

- O grupo `Caixa` atual contém ações, mas todas são preparatórias no menu.
- A tela real é `OperacoesCaixaWebPage`, hoje acionada por `Financeiro > Operações de Caixa`.
- Recomendação: mover `Operações de Caixa` para a área principal `Caixa`.

Financeiro:

- `Contas a receber`, `Contas a pagar` e `Recebimentos futuros` deveriam ser filtros/abas de `AgendaFinanceiraWeb`, não entradas globais.
- `Fiado` e `Crediário` ainda não devem aparecer.

Configurações:

- `Empresa`, `Regionalização`, `Formas de recebimento`, `Regras operacionais` e `Cores e Fontes` possuem telas/conteúdos reais.
- `Notificações`, `Modelos de PDF`, `Integrações` e a entrada atual de `Usuários e permissões` são incompletas ou genéricas.
- Recomendação: uma única entrada `Configurações` na Sidebar e central interna de configurações.

## 7. Destinos versus ações

DESTINOS recomendados:

| Destino | Ações internas |
| --- | --- |
| Início | Nova venda, Novo atendimento, Novo orçamento, Receber, Operações de caixa |
| Frente de caixa | Nova venda, identificar cliente, receber, finalizar venda |
| Assistências técnicas | Novo atendimento, editar, receber, mudar status, gerar link de assinatura |
| Catálogo > Produtos | Novo produto, editar produto, imprimir PDF |
| Catálogo > Serviços | Novo serviço, editar serviço |
| Catálogo > Estoque | Entrada, saída, ajuste, lista de produtos |
| Pessoas > Clientes | Novo cliente, editar cliente |
| Pessoas > Colaboradores | Novo colaborador, editar permissões |
| Caixa | Abrir, fechar, sangria, suprimento, retirada, ajuste |
| Financeiro > Agenda financeira | Receber, pagar, filtrar contas, confirmar liquidação |
| Configurações | Abrir seções internas |

AÇÕES retiradas da navegação global:

```text
Nova venda
Novo atendimento
Nova assistência técnica
Novo orçamento
Abrir caixa
Fechar caixa
Sangria
Suprimento
Retirada para despesa
Ajustes
Receber pagamento
Cadastrar cliente
Cadastrar produto
Cadastrar serviço
```

## 8. Atendimento e Vendas

Recomendação: manter `Vendas` dentro de `Atendimento` na V1, usando o subitem `Frente de caixa`.

Motivo:

- O fluxo real pós-login já trata venda como operação de atendimento no balcão.
- Mobile também organiza ações de venda/orçamento/assistência dentro de `Atendimento`.
- Separar `Vendas` como área principal agora aumentaria o número de conceitos sem uma tela Web persistente dedicada a vendas.
- Para comércios focados em venda, `Frente de caixa` continua claro e direto.

Estrutura recomendada:

```text
Atendimento
├── Frente de caixa
└── Assistências técnicas
```

`Orçamentos` entra depois como subitem quando existir destino real de gestão/lista.

## 9. Caixa e Financeiro

Diferença funcional pelo código:

- `Caixa` é operação diária de sessão: abrir, fechar, movimentar, ver saldo e resumo. Tela real: `OperacoesCaixaWebPage`.
- `Financeiro` é agenda/compromissos: contas, vencimentos, liquidações e valores confirmados. Tela real: `AgendaFinanceiraWeb`.

Recomendação:

```text
Caixa
└── Operação de caixa

Financeiro
└── Agenda financeira
```

`Contas a receber`, `Contas a pagar` e `Recebimentos futuros` devem virar filtros/cards dentro da Agenda, não itens da Sidebar.

## 10. Relatórios

Recomendação: Opção A, mas não na V1 visível.

```text
Relatórios
└── Hub interno
    ├── Vendas
    ├── Assistências
    ├── Caixa
    ├── Financeiro
    ├── Produtos
    └── Clientes
```

Motivo:

- O menu atual chama `_mostrarPreparacao(context, 'Relatório de $value')`.
- Não há hub Web real de relatórios.
- Existe relatório PDF de produtos dentro da lista de produtos, então esse caso deve permanecer contextual.
- Exibir relatórios individuais na Sidebar recriaria o problema atual.

Decisão: ocultar `Relatórios` até existir hub real. Quando existir, deve ser um único item principal.

## 11. Configurações

Recomendação: uma única entrada `Configurações`.

Dentro da página de configurações, organizar por seções:

```text
Configurações
├── Empresa
├── Aparência
├── Regionalização
├── Formas de recebimento
├── Regras operacionais
├── Usuários e permissões
├── Notificações
├── Modelos de PDF
└── Integrações
```

Não colocar essas seções como subitens permanentes da Sidebar V1.

Evidência:

- `ConfiguracaoSecaoWebPage` tem conteúdo real para Empresa, Regionalização, Formas de recebimento e Regras operacionais.
- `CoresFontesWebPage` é real.
- Outras seções caem em `_buildBlankContent()`.

## 12. Itens preparatórios

Ocultar da nova navegação até existir:

```text
Novo orçamento
Orçamentos
Vendas
Fiado
Crediário
Relatório de Vendas
Relatório de Assistências
Relatório de Caixa
Relatório Financeiro
Relatório de Clientes
Notificações
Modelos de PDF
Integrações
Fornecedores
```

Remover da navegação global, mas manter como ações contextuais:

```text
Abrir caixa
Fechar caixa
Movimentações
Suprimento
Sangria
Retirada para despesa
Ajustes
Resumo do caixa
Contas a receber
Contas a pagar
Recebimentos futuros
```

## 13. Grupo Legado

Grupo atual:

```text
Legado
├── Categorias
└── Preferências do Six
```

Análise:

- `Categorias` já tem substituto moderno em `Catálogo > Categorias`.
- `Preferências do Six` abre `ConfiguracoesSixWebPage`, que ainda contém muitos mocks/estado local.
- O grupo provavelmente existe para manter acesso a fluxos anteriores enquanto o menu novo evolui.
- Não deve aparecer para o usuário na Sidebar.
- Pode continuar existindo internamente enquanto callbacks antigos ainda dependem dele.

Decisão: `LEGADO INTERNO`.

## 14. Permissões

Permissões reais disponíveis:

```text
podeFazerVenda
podeLancarAssistenciaTecnica
podeEditarCliente
podeCadastrarProduto
podeEditarProduto
podeVerEstoqueDeProduto
podeAcessarCatalogo
podeGerarRelatorio
podeAcessarFinanceiro
```

Mapeamento recomendado:

| Área | Visibilidade | Ações internas |
| --- | --- | --- |
| Início | todo usuário autenticado | cards e ações filtrados por permissão |
| Atendimento | `podeFazerVenda || podeLancarAssistenciaTecnica` | venda por `podeFazerVenda`; assistência por `podeLancarAssistenciaTecnica` |
| Catálogo | `podeAcessarCatalogo` | produto/serviço por produto; estoque por `podeVerEstoqueDeProduto` |
| Pessoas | se tiver cliente, colaborador ou desempenho disponível | clientes por `podeEditarCliente`; colaboradores precisa regra ADMIN; desempenho por `podeGerarRelatorio` |
| Caixa | `podeAcessarFinanceiro` ou `podeReceberNoCaixa` direto do model | abrir/fechar/movimentar por `podeReceberNoCaixa` |
| Financeiro | `podeAcessarFinanceiro` | valores por `podeVerQuantoVendeu`; receber por `podeReceberNoCaixa` |
| Relatórios | `podeGerarRelatorio` | relatórios internos |
| Configurações | lacuna | ideal ADMIN ou permissões específicas futuras |

Lacunas atuais:

- Não há getter específico para gerenciar colaboradores/usuários.
- Não há permissão específica para configurações.
- Não há permissão específica para fornecedores.
- Não há permissão específica para orçamentos.

## 15. Sidebar recomendada

Sidebar V1 visível:

```text
🏠 Início
🛎️ Atendimento
   ├── Frente de caixa
   └── Assistências técnicas
📦 Catálogo
   ├── Produtos
   ├── Serviços
   ├── Estoque
   └── Categorias
👥 Pessoas
   ├── Clientes
   ├── Colaboradores
   └── Desempenho
💵 Caixa
📊 Financeiro
   └── Agenda financeira
⚙️ Configurações
```

Reservado para entrada futura, oculto na V1:

```text
📄 Relatórios
```

Estado expandido:

```text
🏠 Início
🛎️ Atendimento
📦 Catálogo
👥 Pessoas
💵 Caixa
📊 Financeiro
⚙️ Configurações
```

Estado recolhido:

```text
🏠
🛎️
📦
👥
💵
📊
⚙️
```

Comportamento recomendado:

- tooltip sempre no estado recolhido;
- indicador ativo por barra lateral e cor de fundo;
- expansão automática temporária ao hover opcional, sem mudar preferência salva;
- submenus em no máximo um nível;
- estado recolhido/expandido pode virar preferência individual futura.

## 16. Header recomendado

Migrar para Header:

- toggle da Sidebar;
- comércio atual;
- busca/atalho opcional;
- status de backend;
- notificações;
- IA;
- usuário/perfil;
- logout;
- versão do app.

Origem atual:

- IA, status, notificações e logout estão em `PaginaPrincipalWeb._buildAreaNotificacoesEConexao()`.
- notificações também aparecem no `TopNavigationBarWeb` via `notificationWidget`.
- versão aparece em `_AppVersionPill` dentro do menu superior.

Comércio atual deve ficar no Header, não na Sidebar nem só na Home. Motivo: é contexto global que afeta todas as telas e todos os requests via `idUnicoDaEmpresa`.

## 17. Ações rápidas da Home

Recomendação V1, 5 ações:

```text
Nova venda
Novo atendimento
Novo orçamento
Receber
Operações de caixa
```

Motivo:

- cobrem balcão, assistência, orçamento, financeiro imediato e caixa;
- são ações de alto volume;
- não precisam ocupar navegação global;
- podem respeitar permissões individualmente.

Ação opcional se houver espaço/contexto:

```text
Cadastrar cliente
```

## 18. Ações contextuais por módulo

```text
ATENDIMENTO

Frente de caixa
- Nova venda
- Identificar cliente
- Receber
- Finalizar venda

Assistências técnicas
- Novo atendimento
- Editar atendimento
- Receber
- Mudar status
- Gerar link de assinatura

CATÁLOGO

Produtos
- Novo produto
- Editar produto
- Imprimir PDF

Serviços
- Novo serviço
- Editar serviço

Estoque
- Entrada
- Saída
- Ajuste
- Ver lista completa

Categorias
- Nova categoria
- Editar categoria

PESSOAS

Clientes
- Novo cliente
- Editar cliente

Colaboradores
- Novo colaborador
- Editar permissões

CAIXA

- Abrir caixa
- Fechar caixa
- Sangria
- Suprimento
- Retirada para despesa
- Ajuste
- Ver movimentações

FINANCEIRO

Agenda financeira
- Receber
- Pagar
- Filtrar a receber
- Filtrar a pagar
- Ver vencidos
- Ver vencendo hoje
```

## 19. Wireframe textual

```text
┌────────────────────┬──────────────────────────────────────────────┐
│ SIXAPP             │ [≡] Empresa atual      Busca...  🔔 ✨ 👤    │
│                    ├──────────────────────────────────────────────┤
│ 🏠 Início          │                                              │
│ 🛎️ Atendimento     │                                              │
│   Frente de caixa  │                                              │
│   Assistências     │                  CONTEÚDO                    │
│ 📦 Catálogo        │                                              │
│   Produtos         │                                              │
│   Serviços         │                                              │
│   Estoque          │                                              │
│   Categorias       │                                              │
│ 👥 Pessoas         │                                              │
│ 💵 Caixa           │                                              │
│ 📊 Financeiro      │                                              │
│                    │                                              │
│ ⚙️ Configurações   │                                              │
└────────────────────┴──────────────────────────────────────────────┘
```

## 20. Compatibilidade com crescimento futuro

A proposta acomoda crescimento sem reorganização completa:

- devoluções/trocas: ação ou subitem futuro em `Atendimento`;
- agenda operacional: subitem futuro em `Atendimento` ou `Início`, conforme produto;
- fidelização/CRM: subitem futuro em `Pessoas`;
- integrações: seção interna de `Configurações`;
- relatórios adicionais: hub único `Relatórios`;
- automações: seção futura em `Configurações` ou área própria só se crescer muito;
- novas funcionalidades financeiras: dentro de `Financeiro`, evitando subitens globais prematuros.

## 21. Estratégia técnica de implementação

Sequência recomendada:

```text
Fase 1
Criar WebNavigationRegistry sem alterar aparência.

Fase 2
Fazer TopNavigationBarWeb consumir o registry mantendo o menu superior.

Fase 3
Adicionar predicates de permissão no registry.

Fase 4
Criar AuthenticatedWebShell com Header + Content, ainda sem trocar tudo.

Fase 5
Criar Sidebar consumindo o mesmo registry.

Fase 6
Migrar PaginaPrincipalWeb para rodar dentro do shell ou delegar conteúdo ao shell.

Fase 7
Mover notificações, IA, versão, usuário e logout para Header.

Fase 8
Ocultar TopNavigationBarWeb quando Sidebar estiver validada.

Fase 9
Converter gradualmente módulos críticos em rotas estáveis.
```

Essa ordem reduz risco porque o registry nasce antes da troca visual.

## 22. Arquivos que futuramente seriam envolvidos

Principais existentes:

```text
lib/top_navigation_bar_web.dart
lib/pagina_principal_web.dart
lib/main.dart
lib/providers/colaborador_autorizacoes_provider.dart
lib/data/models/colaborador_autorizacoes_model.dart
lib/presentation/components/dashboard_inicio_web.dart
lib/presentation/screens/atendimentos_tecnicos_web_page.dart
lib/presentation/screens/atendimentos_tecnicos_lista_web_page.dart
lib/presentation/screens/agenda_financeira_web.dart
lib/presentation/screens/operacoes_caixa_web_page.dart
lib/presentation/screens/produto_dashboard_web_page.dart
lib/presentation/screens/servico_dashboard_web_page.dart
lib/presentation/screens/estoque_dashboard_web_page.dart
lib/presentation/screens/clientes_usuario_list_page.dart
lib/presentation/screens/colaboradores_usuario_web_page.dart
lib/presentation/screens/categorias_produtos_servicos_web_page.dart
lib/presentation/screens/configuracao_secao_web_page.dart
lib/presentation/screens/cores_fontes_web_page.dart
```

Novos conceituais futuros:

```text
lib/presentation/navigation/web_navigation_registry.dart
lib/presentation/navigation/web_navigation_item.dart
lib/presentation/layouts/authenticated_web_shell.dart
lib/presentation/components/web_sidebar_navigation.dart
lib/presentation/components/web_header.dart
```

## 23. Riscos

- Duplicar menu em Sidebar e TopNavigationBar sem registry.
- Exibir ações como se fossem destinos.
- Mostrar placeholders na nova Sidebar.
- Aplicar permissões só visualmente e esquecer ações internas.
- Quebrar callbacks de `PaginaPrincipalWeb`.
- Aumentar uso de `embedded: true` como arquitetura permanente.
- Criar Sidebar antes de separar Header.
- Colocar comércio atual na Home e deixar o restante do app sem contexto visível.
- Transformar `Relatórios` em catálogo enorme de links.
- Deixar `Configurações` virar outro menu gigante.

## 24. Decisões de produto ainda pendentes

- `Orçamentos` deve ter lista própria ou continuar como ação?
- `Relatórios` entra na V1 ou só depois do hub real?
- Colaboradores/permissões devem ficar em `Pessoas`, `Configurações` ou ambos?
- `Fornecedores` deve aparecer só quando houver backend real?
- O nome final deve ser `Atendimento` ou `Vendas e atendimento`?
- Configurações terá busca interna?
- Sidebar recolhida deve ser preferência individual?
- O comércio atual terá seletor no Header já na primeira versão?
- Quais seções de configuração são ADMIN-only?
- Caixa deve ser visível para quem só pode receber no caixa, mesmo sem acesso financeiro amplo?

## 25. Navegação Web recomendada

```text
🏠 Início

🛎️ Atendimento
├── Frente de caixa
└── Assistências técnicas

📦 Catálogo
├── Produtos
├── Serviços
├── Estoque
└── Categorias

👥 Pessoas
├── Clientes
├── Colaboradores
└── Desempenho

💵 Caixa

📊 Financeiro
└── Agenda financeira

⚙️ Configurações
```

Reservado, mas oculto até implementação real:

```text
📄 Relatórios
```
