# Diagnóstico Web SixApp

## 1. Resumo executivo

Hoje o fluxo Web pós-login termina, por padrão, em `/app`, renderizando `PaginaPrincipalWeb` (`lib/pagina_principal_web.dart`). A primeira área visível dentro dessa página é `DashboardInicioWeb` (`lib/presentation/components/dashboard_inicio_web.dart`), porque `_moduloAtual` inicia como `ModuloCentralPDV.seletor`.

A experiência inicial atual mistura três camadas no mesmo lugar:

- shell visual autenticado;
- roteamento interno por estado;
- módulos de negócio, especialmente PDV, dashboard inicial, notificações e overlays.

O menu superior atual é implementado por `TopNavigationBarWeb` (`lib/top_navigation_bar_web.dart`). Ele concentra boa parte da navegação real, abre telas por overlay, chama callbacks legados de `PaginaPrincipalWeb` e também possui várias entradas ainda preparatórias. A navegação efetiva possui 8 grupos principais e 49 subitens. Isso explica por que o menu está chegando ao limite: o problema não é só visual; a lógica de navegação também está concentrada no componente do menu.

A tela inicial atual parece operacional, mas os dados de `DashboardInicioWeb` são mockados por `DashboardInicioProvider` e `DashboardInicioMock`. Ao mesmo tempo, existe um endpoint legado real `/private/api/web/telainicial`, consumido por `TelaInicialWebService`, mas ele é carregado no splash pós-login e não é consumido pela Home Web atual.

Há bons blocos reutilizáveis para uma futura Home Web:

- autenticação e contexto de empresa em `AuthService`;
- permissões em `ColaboradorAutorizacoesProvider`;
- regionalização em `LocaleSettingsProvider`;
- atendimento técnico em `AtendimentoTecnicoService`;
- agenda financeira em `AgendaFinanceiraLancamentoService`;
- caixa em `CaixaService`/`CaixaApiClient`;
- catálogo/estoque em `ProdutoService` e dashboards Web;
- componentes visuais em `web_dashboard_widgets.dart`.

Para uma futura Home "Meu dia no SixApp", parte dos dados já existe, mas está espalhada. A melhor evolução com menor risco é preservar os módulos atuais e introduzir uma camada Web de workspace de forma incremental: primeiro uma fonte central de navegação, depois um shell Web autenticado, depois a Home com dados reais. Uma Sidebar esquerda retrátil é viável, mas deve nascer de uma arquitetura de navegação centralizada, não como troca isolada de widget.

Branch sugerida para a futura experimentação: `feature/web-workspace-home-sidebar`.

## 2. Fluxo atual pós-login

Fluxo real encontrado:

```text
LoginPageWeb
  -> AuthService.login()
  -> POST /auth/web/login
  -> AuthService._saveAuthData()
  -> EmpresaService.buscarDadosDaEmpresa()
  -> LoginPageWeb._navigateToPostLoginSplash()
  -> PostLoginSplashWebPage
  -> bootstrap de usuario, permissoes, regionalizacao, aparencia e tela inicial legada
  -> Navigator.pushNamedAndRemoveUntil(nextRoute)
  -> /app
  -> PaginaPrincipalWeb
  -> ModuloCentralPDV.seletor
  -> DashboardInicioWeb
```

Referências principais:

- `lib/presentation/screens/login_page_web.dart`
- `lib/domain/services/auth_service.dart`
- `lib/presentation/screens/post_login_splash_web_page.dart`
- `lib/main.dart`
- `lib/pagina_principal_web.dart`

O login Web é feito por `LoginPageWeb._login()`. Ele valida `login` e `senha`, chama `AuthService.login(login, senha)` e, em sucesso, chama `_navigateToPostLoginSplash()`.

`AuthService.login()` decide o canal pelo Flutter:

```dart
final pathLogin = kIsWeb ? 'web' : 'mobile';
```

Na Web, o endpoint chamado é:

```text
POST /auth/web/login
```

O payload enviado é `login` e `senha`. Em resposta `200`, `AuthService` monta `AuthResponseModel`, salva token e dados do usuário em `SharedPreferences`, agenda refresh, busca dados da empresa e retorna sucesso.

O destino após login é decidido em `LoginPageWeb._redirectAfterLogin()` e `LoginPageWeb._navigateToPostLoginSplash()`:

- se o usuário veio de `/admin`, o destino vira `/admin/dashboard`;
- se a URL possui `?redirect=/...`, esse redirect é respeitado quando considerado seguro;
- caso contrário, o destino padrão é `/app`.

O splash pós-login é `PostLoginSplashWebPage`. Ele executa `_bootstrapAuthenticatedSession()` antes de navegar para a rota final. Esse bootstrap carrega:

- usuário atual por `UsuarioService().buscarDadosDoUsuario_atualizaProviders()`;
- autorizações por `ColaboradorAutorizacoesProvider.carregarAutorizacoesDoUsuarioLogado(force: true)`;
- regionalização por `RegionalizacaoService(HttpRegionalizacaoApiClient()).buscarRegionalizacao()`;
- aparência por `AparenciaService(HttpAparenciaApiClient()).buscarAparencia()`;
- dados legados da tela inicial por `TelaInicialWebService().atualizaProviders()`.

Em `main.dart`, as rotas Web são controladas por `_onGenerateWebRoute()`. A rota `/app` renderiza `PaginaPrincipalWeb`.

Diferença ADMIN/colaborador:

- O login pode redirecionar para `/admin/dashboard` se a origem for `/admin`.
- Para a aplicação principal em `/app`, não encontrei uma decisão de primeira tela diferente para ADMIN versus colaborador.
- O tipo de perfil pode ser inferido por `AuthService.getUserProfileType()`, que lê `usuario.permissoes` e retorna `ADMIN`, `COLABORADOR` ou `DESCONHECIDO`.
- As permissões são carregadas no splash, mas a primeira tela Web atual não muda automaticamente conforme permissões.

Preferência individual:

- Existe infraestrutura de preferência em `UsuarioService` e `PreferenciasIndividuaisDoUsuarioModel`.
- Ela cobre idioma, modo de visualização de produtos/serviços, ocultar valores financeiros Web, filtros da Agenda Financeira e filtros de Atendimentos Criados.
- Não encontrei preferência individual para rota inicial, workspace padrão ou estado recolhido/expandido de uma futura Sidebar.

## 3. Primeira tela atual

A primeira tela autenticada padrão é:

```text
Rota: /app
Widget: PaginaPrincipalWeb
Arquivo: lib/pagina_principal_web.dart
Modulo inicial: ModuloCentralPDV.seletor
Conteudo inicial: DashboardInicioWeb
Arquivo: lib/presentation/components/dashboard_inicio_web.dart
```

Em `PaginaPrincipalWeb`, o estado inicial é:

```dart
ModuloCentralPDV _moduloAtual = ModuloCentralPDV.seletor;
```

O método `_buildConteudoCentral()` escolhe o conteúdo pelo enum `ModuloCentralPDV`. Quando o módulo é `seletor`, ele chama `_buildSeletorModoOperacao()`, que renderiza `DashboardInicioWeb`.

`DashboardInicioWeb` recebe:

- `compact`;
- `onIniciarVenda`;
- `onAbrirAtendimentoTecnico`.

Ele cria localmente um `ChangeNotifierProvider<DashboardInicioProvider>`. Esse provider não chama backend. A fonte atual é:

- `lib/providers/dashboard_inicio_provider.dart`;
- `lib/data/mock/dashboard_inicio_mock.dart`;
- `lib/data/models/dashboard_inicio_model.dart`.

O próprio provider declara que é uma fonte simulada para sustentar a interface até a integração real. A Home atual apresenta:

- abas `Gestão` e `Equipe`;
- KPIs de vendas, valor recebido, a receber e resultado;
- gráfico de evolução do período;
- seção `Atenção necessária`;
- seção `Próximos 7 dias`;
- resumo operacional com atendimentos em andamento, orçamentos aguardando, equipamentos para retirada e caixas abertos;
- ações para iniciar venda e abrir atendimento técnico.

Chamadas de backend realizadas pela Home atual:

- `DashboardInicioWeb` não realiza chamadas reais.
- O splash pós-login chama `TelaInicialWebService().atualizaProviders()`, que consulta `/private/api/web/telainicial`, mas a Home atual não consome esse provider.

Endpoint legado já existente:

```text
GET /private/api/web/telainicial
```

Referências:

- `lib/domain/services/telainicial_web/tela_inicial_web_service.dart`
- `lib/data/services/telainicial_web/tela_inicial_api_client.dart`
- `lib/data/models/tela_inicial_models.dart`

O modelo legado `TelaInicialModel` contém:

- `totalVendasAbertas`;
- `totalAtendimentoTecnicosNaoEntregues`;
- `totalAtendimentoTecnicoEmAndamento`;
- `totalAtendimentoTecnicoAguardandoAssinatura`;
- `totalOrdensDeServicoAbertas`.

Elementos exclusivos Web:

- `PaginaPrincipalWeb`;
- `DashboardInicioWeb`;
- `TopNavigationBarWeb`;
- dashboards Web de produto, estoque e serviços;
- páginas Web com modo `embedded`.

Elementos compartilhados com Mobile:

- services e API clients;
- models;
- providers globais;
- autenticação;
- permissões;
- regionalização;
- parte da lógica de agenda/catálogo em providers reutilizáveis.

Ponto de atenção: `DashboardInicioWeb` usa `NumberFormat.currency(locale: 'pt_BR', symbol: 'R$')` e datas `pt_BR`. Para uma futura Home real, isso deve ser substituído por `LocaleSettingsProvider`, conforme a regra global de regionalização.

## 4. Arquitetura de navegação

A navegação Web autenticada atual é uma combinação de:

- rotas Web declaradas em `main.dart`;
- estado interno em `PaginaPrincipalWeb`;
- callbacks passados para `TopNavigationBarWeb`;
- overlays abertos pelo próprio `TopNavigationBarWeb`;
- páginas `embedded: true`;
- algumas rotas públicas ou específicas fora do app principal.

Arquivos centrais:

- `lib/main.dart`
- `lib/pagina_principal_web.dart`
- `lib/top_navigation_bar_web.dart`

`PaginaPrincipalWeb` funciona como um pseudo-shell da aplicação autenticada. Ela monta:

- `Scaffold`;
- `TopNavigationBarWeb`;
- área de conteúdo;
- notificações WebSocket;
- IA;
- logout;
- controle de módulo central.

O conteúdo principal não é dirigido majoritariamente por rotas nomeadas. Muitos módulos são abertos por alteração de `_moduloAtual` ou por `showDialog` em `TopNavigationBarWeb._abrirOverlay()`.

Principais módulos internos em `PaginaPrincipalWeb`:

```text
ModuloCentralPDV
├── seletor
├── cockpit
├── vendas
├── recebimento
├── clientesList
├── colaboradoresList
├── orcamento
├── operacoesCaixa
├── ordemServico
├── agendaFinanceira
├── atendimentoTecnico
├── categorias
└── configuracoes
```

Não encontrei breadcrumb na navegação autenticada Web. Também não encontrei Drawer, Sidebar ou `NavigationRail` para o app principal. Há um shell com sidebar/drawer apenas para a área administrativa, em `lib/presentation/admin/admin_navigation_shell.dart`.

## 5. Menu superior atual

O menu superior é `TopNavigationBarWeb`.

Arquivo:

```text
lib/top_navigation_bar_web.dart
```

Embora `PaginaPrincipalWeb` passe uma lista de itens legados, `TopNavigationBarWeb._itemsEfetivos()` substitui essa lista por um novo menu interno quando detecta itens como `Cadastros`, `Configurações` e `Início`.

Representação aproximada do menu efetivo atual:

```text
Menu atual
├── Atendimento
│   ├── PDV - Frente de Caixa
│   ├── Atendimento técnico
│   ├── Atendimentos criados
│   ├── Novo orçamento
│   ├── Nova assistência técnica
│   ├── Vendas
│   ├── Orçamentos
│   └── Assistências técnicas
├── Catálogo
│   ├── Produtos
│   ├── Serviços
│   ├── Categorias
│   └── Estoque
├── Pessoas
│   ├── Meu Perfil
│   ├── Clientes
│   ├── Colaboradores
│   ├── Fornecedores
│   └── Desempenho
├── Caixa
│   ├── Abrir caixa
│   ├── Fechar caixa
│   ├── Movimentações
│   ├── Suprimento
│   ├── Sangria
│   ├── Retirada para despesa
│   ├── Ajustes
│   └── Resumo do caixa
├── Financeiro
│   ├── Contas a receber
│   ├── Contas a pagar
│   ├── Recebimentos futuros
│   ├── Fiado
│   ├── Crediário
│   ├── Agenda financeira
│   └── Operações de Caixa
├── Relatórios
│   ├── Vendas
│   ├── Assistências
│   ├── Caixa
│   ├── Financeiro
│   ├── Produtos
│   └── Clientes
├── Configurações
│   ├── Empresa
│   ├── Cores e Fontes
│   ├── Usuários e permissões
│   ├── Regionalização
│   ├── Formas de recebimento
│   ├── Regras operacionais
│   ├── Notificações
│   ├── Modelos de PDF
│   └── Integrações
└── Legado
    ├── Categorias
    └── Preferências do Six
```

Quantidade:

- 8 grupos principais;
- 49 subitens.

Nem todos os subitens abrem uma tela real. Vários chamam `_mostrarPreparacao()`, exibindo snackbar com mensagem de tela futura/preparatória. Exemplos:

- `Novo orçamento`;
- `Vendas`;
- `Orçamentos`;
- diversas ações de `Caixa`;
- `Contas a receber`;
- `Contas a pagar`;
- relatórios.

Há também duplicidades ou sobreposição semântica:

- `Atendimento técnico`, `Nova assistência técnica` e `Assistências técnicas`;
- `Atendimentos criados` e `Assistências técnicas`;
- `Caixa` possui ações preparatórias, enquanto a tela real `Operações de Caixa` está em `Financeiro`;
- `Contas a receber` está como preparação no menu, mas existe `VendasAReceberWebWidget` acessível pelo PDV.

Comportamento responsivo:

- O menu usa `SingleChildScrollView` horizontal no topo.
- Isso evita overflow imediato, mas reduz descoberta quando há muitos grupos.
- Não há hierarquia lateral persistente, indicador forte de seção ativa ou breadcrumb.

Dependência arquitetural do menu:

- Alta na camada visual: o menu importa telas de módulo e abre overlays diretamente.
- Média na navegação: muitos fluxos dependem de callbacks ou dialogs, não de rotas nomeadas.
- Baixa no backend: os services não dependem do menu.
- Fraca em permissões: o menu não centraliza regras de visibilidade por autorização.

Conclusão técnica: o menu superior está no limite de escalabilidade porque concentra descoberta, roteamento, overlays e itens futuros em um único componente horizontal.

## 6. Inventário funcional Web

### Acesso, conta e sessões

- Login Web: `LoginPageWeb`.
- Cadastro público: `RegisterPageWeb`.
- Esqueci senha: `EsqueceuSenhaWeb`.
- Splash pós-login: `PostLoginSplashWebPage`.
- Landing pública: `WebRootPage`, `DesktopLayout`, `MobileLayout`.
- Logout: ação em `PaginaPrincipalWeb`.

### Operação de venda e PDV

- PDV/frente de caixa: `PaginaPrincipalWeb`, módulo `ModuloCentralPDV.vendas`.
- Seleção de recebimento: `RecebimentoPagamentoWeb`.
- Finalização de venda: `OperacaoService.finalizarVenda()`.
- Impressão de comprovante: `OperacaoService.imprimirComprovanteDaOperacao()`.
- Vendas não liquidadas/a receber: `VendasAReceberWebWidget`.
- API de operação: `OperacaoApiClient`, endpoint `/operacao/inserir`.
- API de vendas a receber: `VendaNaoLiquidadaApiClient`, endpoint `/private/api/caixa/vendas-nao-liquidadas`.

### Atendimento técnico, assistência e orçamento

- Novo atendimento técnico: `AtendimentosTecnicosWebPage`.
- Lista de atendimentos criados: `AtendimentosTecnicosListaWebPage`.
- Status de atendimento técnico: `StatusAtendimentoTecnicoConfigWebPage`.
- Página pública de assinatura: rota `/atendimento/assinatura`.
- Página pública de status: rota `/atendimento/status`.
- Orçamento Web: `OrcamentoWeb`.
- Ordem de serviço Web: `OrdemServicoWeb`.
- Service principal: `AtendimentoTecnicoService`.
- API principal: `AtendimentoTecnicoApiClient`, endpoints sob `/atendimentos-tecnicos`.

### Caixa

- Operações de caixa: `OperacoesCaixaWebPage`.
- Sessão atual: `CaixaService.buscarSessaoAtual()` / `CaixaApiClient.getSessaoAtual()`.
- Abertura de caixa: `CaixaApiClient.abrirCaixa()`.
- Movimentações: `CaixaApiClient.criarMovimento()` e `CaixaApiClient.getMovimentos()`.
- Resumo: `CaixaApiClient.getResumo()` e `getResumoDeMovimentosComSomatorio()`.
- Fechamento: `CaixaApiClient.fecharCaixa()`.

### Financeiro

- Agenda financeira Web: `AgendaFinanceiraWeb`.
- Consulta de lançamentos: `AgendaFinanceiraLancamentoService.consultarLancamentos()`.
- Consulta de valores confirmados: `AgendaFinanceiraLancamentoService.consultarValoresConfirmados()`.
- Confirmação/liquidação: `AgendaFinanceiraAcoesFinanceiras`.
- Filtros persistidos por preferência individual: `UsuarioService.atualizarPreferenciasIndividuais()`.

### Catálogo, produtos, serviços e estoque

- Produtos: `ProdutoDashboardWebPage`, `SubPainelWebProdutoLista`, cadastro de produto por subpainel.
- Serviços: `ServicoDashboardWebPage`.
- Categorias: `CategoriasProdutosServicosWebPage`.
- Estoque: `EstoqueDashboardWebPage`.
- Service principal: `ProdutoService`.
- Endpoints:
  - `/private/api/produto/lista`;
  - `/private/api/produto/cadastro`;
  - `/private/api/produto/atualizacao`;
  - `/private/api/produto/dashboard`;
  - `/private/api/produto/estoque/dashboard`;
  - `/private/api/produto/servicos/dashboard`.

### Pessoas

- Clientes: `ClientesUsuarioListPage`.
- Cadastro/edição de cliente: dialogs/subpainéis associados a cliente.
- Colaboradores: `ColaboradoresUsuarioListPage` e telas Web de colaborador.
- Fornecedores: `FornecedoresUsuarioListPage`.
- Desempenho de colaborador: `DesempenhoColaboradorWebPage`.
- Perfil: tela de perfil aberta pelo menu superior.

### Configurações

- Configurações gerais: `ConfiguracoesSixWebPage`.
- Configuração por seção genérica: `ConfiguracaoSecaoWebPage`.
- Aparência/cores/fontes: página específica aberta pelo menu superior.
- Regionalização: service/provider global, com tela de configuração associada.
- Status de atendimento técnico: `StatusAtendimentoTecnicoConfigWebPage`.
- Usuários e permissões: telas de colaboradores/autorização.

### Administração

- Portal admin: `AdminPortalWebPage`, rota `/admin/dashboard`.
- Usuários ativos: `AdminUsuariosAtivosWebPage`, rota `/admin/usuarios`.
- Novas ideias: `AdminNovasIdeiasWebPage`, rota `/admin/novas-ideias`.
- Shell admin: `AdminNavigationShell`.

### Notificações e tempo real

- Conexão WebSocket: `lib/services/websocket_service.dart`.
- Eventos em memória: `NotificacaoService`.
- Painel/ícone de notificações no topo de `PaginaPrincipalWeb` e `TopNavigationBarWeb`.

### IA

- Painel de assistente: `AiAssistantPanel`.
- Ele consome permissões do `ColaboradorAutorizacoesProvider` para montar flags de contexto.

## 7. Estrutura de rotas

Rotas Web principais em `main.dart`:

```text
/                                  -> WebRootPage
/home                              -> WebRootPage
/login                             -> LoginPageWeb
/admin                             -> LoginPageWeb
/admin/dashboard                   -> AdminPortalWebPage
/admin/usuarios                    -> AdminUsuariosAtivosWebPage
/admin/novas-ideias                -> AdminNovasIdeiasWebPage
/register                          -> RegisterPageWeb
/forgot-password                   -> EsqueceuSenhaWeb
/app                               -> PaginaPrincipalWeb
/app/atendimentos-tecnicos         -> AtendimentosTecnicosWebPage
/app/atendimentos-tecnicos/criados -> AtendimentosTecnicosListaWebPage
/app/configuracoes/status-atendimento-tecnico -> StatusAtendimentoTecnicoConfigWebPage
/atendimento/assinatura            -> AtendimentoTecnicoAssinaturaPublicPage
/atendimento/status                -> AtendimentoTecnicoStatusPublicPage
/onboarding                        -> OnboardingWebPage
/checkout                          -> CheckoutWebPage
/ordem-servico/...                 -> rotas públicas/dinâmicas de OS
/cliente/auto-cadastro...          -> auto cadastro público de cliente
/colaborador/convites/...          -> fluxo de convite de colaborador
```

A maior parte dos módulos operacionais Web não possui rota própria. Exemplos que hoje dependem de estado interno, callbacks ou overlay:

- PDV;
- agenda financeira;
- operações de caixa;
- clientes;
- colaboradores;
- fornecedores;
- produtos;
- serviços;
- estoque;
- categorias;
- configurações genéricas.

Isso significa que refresh, deep link e histórico do navegador não representam bem o módulo aberto quando ele foi acionado internamente por estado ou dialog.

## 8. Permissões

Infraestrutura existente:

- `AuthService.getUserPermissions()`;
- `AuthService.getUserProfileType()`;
- `ColaboradorAutorizacoesProvider`;
- `ColaboradorAutorizacoesModel`.

`ColaboradorAutorizacoesProvider` expõe getters como:

- `podeFazerVenda`;
- `podeLancarAssistenciaTecnica`;
- `podeEditarCliente`;
- `podeCadastrarProduto`;
- `podeEditarProduto`;
- `podeVerEstoqueDeProduto`;
- `podeAcessarCatalogo`;
- `podeGerarRelatorio`;
- `podeAcessarFinanceiro`.

O provider é registrado globalmente em `main.dart` e carregado no `PostLoginSplashWebPage`. A origem dos dados é o colaborador retornado por `ColaboradorUsuarioApiClient.buscarColaborador()`, usando `objAutorizacoes`.

Comportamento atual na Web:

- A infraestrutura existe.
- Mobile já usa esses getters em telas como `GestaoMobileScreen`.
- O painel de IA usa as permissões para enriquecer contexto.
- A edição de permissões existe em telas Web de colaborador.
- O menu superior Web não aplica esses getters de forma centralizada.
- A primeira Home Web atual não filtra os indicadores conforme permissão.

Conclusão: uma futura Sidebar e uma futura Home podem usar a infraestrutura existente sem duplicar regras, mas será necessário centralizar a visibilidade de itens e dados. Hoje isso não acontece automaticamente na navegação Web.

Risco importante: `ColaboradorAutorizacoesProvider` usa `permitirTudo()` como fallback quando as autorizações ainda não existem ou falham em alguns cenários. Isso é aceitável para ADMIN, mas deve ser avaliado com cuidado antes de esconder/mostrar dados financeiros no Web workspace.

## 9. Contexto de comércio

O contexto de comércio é determinado após o login.

Referências:

- `lib/data/models/auth_response_model.dart`
- `lib/domain/services/auth_service.dart`
- `lib/domain/services/empresa_service.dart`
- `lib/providers/empresa_provider.dart`

`AuthResponseModel` possui:

```dart
final List<String> idUnicoDaEmpresa;
```

Porém `AuthService._saveAuthData()` salva apenas o primeiro item:

```dart
await prefs.setString(_empresaIdKey, authResponse.idUnicoDaEmpresa.first);
```

Depois disso, `AuthService.getEmpresaId()` retorna esse valor salvo em `SharedPreferences`. Os API clients e services enviam esse valor no header:

```text
idUnicoDaEmpresa
```

`EmpresaService.buscarDadosDaEmpresa()` usa esse comércio atual para buscar `/private/api/dados-empresa` e atualizar `EmpresaProvider`.

Procurei por padrões como seletor/troca de empresa, empresa ativa, comércio atual e multiempresa. Não encontrei, na Web autenticada, um seletor claro de comércio nem um fluxo de troca de `idUnicoDaEmpresa` depois do login.

Conclusão:

- A Home futura refletiria automaticamente o comércio salvo em `AuthService`, porque os endpoints usam `idUnicoDaEmpresa`.
- Hoje não há evidência de troca de comércio ativa na Web.
- Se ADMIN realmente precisa alternar entre vários comércios, isso exige decisão de produto e provavelmente uma tela/controle específico antes da Home final.

## 10. Componentes compartilhados

Componentes/layouts Web encontrados:

- `TopNavigationBarWeb` (`lib/top_navigation_bar_web.dart`): menu superior autenticado.
- `PaginaPrincipalWeb` (`lib/pagina_principal_web.dart`): pseudo-shell da aplicação autenticada.
- `WebAuthShell` (`lib/presentation/components/web_auth_shell.dart`): shell visual para telas de autenticação.
- `AdminNavigationShell` (`lib/presentation/admin/admin_navigation_shell.dart`): shell admin com sidebar/drawer.
- `web_dashboard_widgets.dart` (`lib/presentation/components/web_dashboard_widgets.dart`): componentes reutilizáveis de dashboards Web.
- `SixBackendLoading` (`lib/presentation/components/six_backend_loading.dart`): loading reutilizável para mensagens/dados do backend.
- `SixWebRecebimentoDialog`: diálogo de recebimento Web.

Componentes compartilhados entre Web/Mobile por camada, não por tela:

- API clients;
- services;
- models;
- providers globais;
- helpers de autenticação, empresa, permissões, regionalização.

Ponto importante: os componentes de tela inteira Web e Mobile são separados na maior parte dos fluxos modernos. A futura evolução Web deve preservar isso e evitar usar telas mobile como adaptação Web ou telas Web como wrapper mobile.

## 11. Dashboards e indicadores existentes

### Dashboard inicial Web

Arquivo:

```text
lib/presentation/components/dashboard_inicio_web.dart
```

Status:

- visual já existe;
- dados mockados;
- não consome endpoint real.

Fonte:

- `DashboardInicioProvider`;
- `DashboardInicioMock`;
- `DashboardInicioModel`.

### Dashboard de produtos

Arquivo:

```text
lib/presentation/screens/produto_dashboard_web_page.dart
```

Fonte:

```text
ProdutoService.buscarDashboardProdutos()
GET /private/api/produto/dashboard
```

Indicadores úteis:

- total de produtos;
- produtos ativos;
- valor de estoque;
- quantidade em estoque;
- produtos abaixo do mínimo;
- sem estoque;
- estoque negativo;
- margem média;
- categorias;
- alertas;
- produtos com estoque baixo;
- produtos por valor de estoque.

### Dashboard de estoque

Arquivo:

```text
lib/presentation/screens/estoque_dashboard_web_page.dart
```

Fonte:

```text
ProdutoService.buscarDashboardEstoque()
GET /private/api/produto/estoque/dashboard
```

Indicadores úteis:

- valor total em estoque;
- quantidade total;
- produtos cadastrados;
- abaixo do mínimo;
- sem estoque;
- estoque negativo;
- acima do máximo;
- sem movimentação;
- alertas;
- produtos para reposição;
- inconsistências;
- movimentações recentes.

### Dashboard de serviços

Arquivo:

```text
lib/presentation/screens/servico_dashboard_web_page.dart
```

Fonte:

```text
ProdutoService.buscarDashboardServicos()
GET /private/api/produto/servicos/dashboard
```

Pode ser relevante para uma Home se a visão operacional incluir serviços vendidos ou catálogo de serviços.

### Agenda financeira

Arquivo:

```text
lib/presentation/screens/agenda_financeira_web.dart
```

Fonte:

```text
AgendaFinanceiraLancamentoService.consultarLancamentos()
POST /private/api/agenda-financeira/consultar

AgendaFinanceiraLancamentoService.consultarValoresConfirmados()
POST /private/api/agenda-financeira/valores-confirmados
```

Indicadores úteis:

- a receber aberto;
- a pagar aberto;
- saldo previsto;
- recebido confirmado;
- pago confirmado;
- saldo confirmado;
- vencidos;
- vence hoje;
- período hoje/próximos 7 dias/mês.

### Operações de caixa

Arquivo:

```text
lib/presentation/screens/operacoes_caixa_web_page.dart
```

Fonte:

```text
CaixaService.buscarSessaoAtual()
CaixaApiClient.getInformacoesBasicasDoCaixa()
CaixaApiClient.getMovimentos()
CaixaApiClient.getResumo()
```

Indicadores úteis:

- caixa aberto/fechado;
- saldo esperado;
- entradas;
- saídas;
- quantidade de movimentos.

### Atendimento técnico

Arquivos:

```text
lib/presentation/screens/atendimentos_tecnicos_web_page.dart
lib/presentation/screens/atendimentos_tecnicos_lista_web_page.dart
```

Fonte:

```text
AtendimentoTecnicoService.listar()
GET /atendimentos-tecnicos
```

Indicadores úteis:

- atendimentos em aberto;
- assinados/não assinados;
- valor aberto;
- entrega atrasada;
- status;
- técnico;
- histórico de status;
- auditoria por atendimento.

### Dashboard de gestão mobile

Arquivo:

```text
lib/providers/management_overview_provider.dart
```

Embora seja usado pelo Mobile, o provider já agrega catálogo, pessoas e financeiro usando services compartilhados. Ele é uma referência útil para lógica de composição de dados, mas a futura Home Web deve ter composição visual própria.

## 12. Dados disponíveis para uma futura Home

| Bloco conceitual | Situação atual | Fonte possível | Observação |
| --- | --- | --- | --- |
| Saudação e usuário | Existe | `UsuarioService`, `UsuarioProvider`, `AuthService` | Carregado no splash pós-login. |
| Comércio atual | Existe parcialmente | `AuthService.getEmpresaId()`, `EmpresaProvider` | Usa o primeiro `idUnicoDaEmpresa`; não encontrei seletor Web. |
| Vendas hoje | Parcial | `OperacaoService`, `VendaNaoLiquidadaApiClient`, talvez backend de operação | Não encontrei endpoint Web agregado de vendas do dia. |
| Valor recebido hoje | Parcial | `CaixaApiClient`, `AgendaFinanceiraLancamentoService` | Pode ser derivado, mas regra precisa ser definida. |
| Serviços ativos | Existe | `TelaInicialWebService`, `AtendimentoTecnicoService` | Endpoint legado já tem totais; lista de atendimentos permite refinar. |
| A receber hoje | Existe | `AgendaFinanceiraLancamentoService`, `VendasAReceberWebWidget` | Agenda já filtra por data/status. |
| Situação do caixa | Existe | `CaixaService.buscarSessaoAtual()` | Regra simples já usada em `OperacoesCaixaWebPage`. |
| Orçamentos aguardando | Parcial | `AtendimentoTecnicoModel`, endpoint de atendimentos, mock da Home | Precisa consolidar regra real. |
| Serviços atrasados | Existe | `AtendimentosTecnicosListaWebPage._entregaAtrasada()` | Regra local pode virar helper ou endpoint agregado. |
| Equipamentos prontos para entrega | Parcial | status de atendimento e endpoint legado | Precisa definir status/código oficial. |
| Contas vencidas/vencendo | Existe | Agenda financeira | Já há status `VENCIDO` e `VENCE_HOJE`. |
| Estoque crítico | Existe | dashboards de produto/estoque, catálogo saúde | Boa fonte para reutilização. |
| Caixa fechado/aberto | Existe | Caixa | Fonte direta. |
| Ações rápidas | Existe | módulos atuais | Algumas ações não possuem rota própria. |
| Atividade recente | Parcial | WebSocket, caixa, estoque, atendimento técnico | Não encontrei timeline global persistida. |

Conclusão: a Home pode nascer com dados reais usando services existentes, mas uma versão eficiente e consistente provavelmente exigirá um endpoint agregador de workspace para reduzir múltiplas chamadas e evitar regras duplicadas no frontend.

## 13. Dados disponíveis para "Precisa da sua atenção"

| Situação | Dados já existem? | Endpoint existente? | Tela que já utiliza | Regra de negócio existente? | Pode reutilizar na Home? |
| --- | --- | --- | --- | --- | --- |
| Orçamentos aguardando aprovação | Parcial | `GET /atendimentos-tecnicos`; legado `/private/api/web/telainicial` tem total relacionado a assinatura | `DashboardInicioWeb` mock; `AtendimentosTecnicosListaWebPage` | Parcial por status/assinatura; não encontrei regra central com esse nome | Sim, mas ideal consolidar regra no backend ou helper compartilhado |
| Serviços técnicos atrasados | Sim | `GET /atendimentos-tecnicos` | `AtendimentosTecnicosListaWebPage` | Sim, local em `_entregaAtrasada()` | Sim, se a regra sair da tela |
| Serviços aguardando cliente | Parcial | `GET /atendimentos-tecnicos` | Lista de atendimentos por status | Depende de status customizado/domínio; não encontrei regra central | Sim, após mapear códigos de status válidos |
| Equipamentos/serviços prontos para entrega | Parcial | `GET /atendimentos-tecnicos`; `/private/api/web/telainicial` traz não entregues | Lista de atendimentos; Home mock | Parcial por status e entrega; não encontrei regra central | Sim, com regra definida |
| Contas a pagar vencidas | Sim | `POST /private/api/agenda-financeira/consultar` | `AgendaFinanceiraWeb`; `ManagementOverviewProvider` | Sim, por `tipoOperacao` e status `VENCIDO` | Sim |
| Contas a receber vencidas | Sim | `POST /private/api/agenda-financeira/consultar`; `GET /private/api/caixa/vendas-nao-liquidadas` | `AgendaFinanceiraWeb`; `VendasAReceberWebWidget` | Sim, por status/data | Sim |
| Compromissos financeiros do dia | Sim | `POST /private/api/agenda-financeira/consultar` | `AgendaFinanceiraWeb` | Sim, período `Hoje` e status `VENCE_HOJE` | Sim |
| Estoque baixo | Sim | `GET /private/api/produto/estoque/dashboard`; `GET /private/api/produto/dashboard`; `/private/api/catalogo/saude` | `EstoqueDashboardWebPage`; `ProdutoDashboardWebPage`; `GestaoMobileScreen` | Sim, backend já agrega | Sim |
| Caixa fechado | Sim | `GET /private/api/caixa/sessao-atual` | `OperacoesCaixaWebPage` | Sim, sessão nula/sem status aberta | Sim |
| Caixa aberto | Sim | `GET /private/api/caixa/sessao-atual` | `OperacoesCaixaWebPage` | Sim, `_temCaixaAberto` | Sim |
| Vendas abertas/a receber | Sim | `/private/api/web/telainicial`; `GET /private/api/caixa/vendas-nao-liquidadas` | `VendasAReceberWebWidget`; tela inicial legada | Parcial | Sim |
| Atendimentos aguardando assinatura | Sim | `/private/api/web/telainicial`; `GET /atendimentos-tecnicos` | `AtendimentosTecnicosListaWebPage` | Parcial por assinatura | Sim |
| Produtos com estoque negativo/sem estoque | Sim | `GET /private/api/produto/estoque/dashboard` | `EstoqueDashboardWebPage` | Sim, agregado pelo backend | Sim |

O maior risco aqui é duplicar regra operacional dentro da Home. As regras mais críticas deveriam ficar em backend ou em camada de domínio reutilizável, não em widgets.

## 14. Ações rápidas reutilizáveis

| Ação rápida | Tela/fluxo existente | Rota existente? | Observação |
| --- | --- | --- | --- |
| Nova venda | `PaginaPrincipalWeb._iniciarVenda()` / módulo `ModuloCentralPDV.vendas` | Não como rota própria; entrada por `/app` | Pode ser callback dentro do shell atual. Para deep link, exigiria rota ou ação inicial. |
| Novo serviço técnico | `AtendimentosTecnicosWebPage` | Sim: `/app/atendimentos-tecnicos` | Já possui fluxo de criação. |
| Novo orçamento | `OrcamentoWeb` | Não encontrei rota própria | Existe como módulo embedded em `PaginaPrincipalWeb`; menu atual marca alguns itens como preparação. |
| Receber | `RecebimentoPagamentoWeb`, `SixWebRecebimentoDialog`, ações em atendimento e vendas a receber | Parcial | Depende do contexto: venda, atendimento ou lançamento financeiro. |
| Pagamento | `AgendaFinanceiraWeb` e `AgendaFinanceiraAcoesFinanceiras` | Não como rota própria | Pode abrir Agenda filtrada, mas hoje isso não está roteado. |
| Operações de caixa | `OperacoesCaixaWebPage` | Não como rota própria principal; aberta por overlay/módulo | Pode ser acionada por callback. |
| Cliente | `ClientesUsuarioListPage` e dialogs de cadastro | Não como rota própria principal | Hoje aberta por módulo/overlay. |
| Produto | `ProdutoDashboardWebPage`, lista/cadastro de produto | Não como rota própria principal | Menu abre dashboard por overlay. |
| Estoque | `EstoqueDashboardWebPage` | Não como rota própria principal | Menu abre dashboard por overlay. |
| Agenda financeira | `AgendaFinanceiraWeb` | Não como rota própria principal | Hoje aberta por módulo/overlay. |

Para uma Home inicial de baixo risco, ações rápidas podem chamar os mesmos callbacks/módulos já existentes. Para uma evolução mais robusta, as ações principais deveriam ganhar rotas Web estáveis.

## 15. Possibilidade de atividade recente

Fontes encontradas:

### WebSocket funcional

Arquivo:

```text
lib/services/websocket_service.dart
```

O WebSocket conecta em:

```text
/ws
```

E assina tópicos:

```text
/topic/empresa/{empresaId}/vendas
/topic/empresa/{empresaId}/produtos
```

Os payloads são enviados para `NotificacaoService`, que mantém eventos em memória. Isso é útil para notificações da sessão atual, mas não é uma timeline persistente.

### Notificações em memória

Arquivo:

```text
lib/services/notificacao_service.dart
```

`SixNotificationEvent` lê campos como:

- `tipoDeEvento`;
- `titulo`;
- `mensagem`;
- `canal`;
- `status`;
- entidade;
- horário recebido.

Isso é evento útil ao usuário, mas não cobre todo o domínio e não sobrevive como histórico global se não houver persistência backend.

### Histórico por domínio

Atendimento técnico possui:

- `AtendimentoTecnicoHistoricoStatusModel`;
- `AtendimentoTecnicoAuditoriaModel`;
- `historicoStatus`;
- `historicoAuditoria`.

Caixa possui movimentações:

- `CaixaApiClient.getMovimentos()`;
- `CaixaApiClient.getResumoDeMovimentosComSomatorio()`.

Estoque possui movimentações recentes no dashboard:

- `EstoqueDashboardModel.movimentacoesRecentes`;
- renderização em `EstoqueDashboardWebPage`.

Agenda financeira possui liquidações/histórico por lançamento.

### O que não encontrei

Procurei por padrões relacionados a atividade, eventos, auditoria, histórico, movimentações, logs, timeline, recentes, WebSocket e notificações. Não encontrei endpoint global de atividade recente do tipo:

```text
GET /private/api/.../atividades
GET /private/api/.../timeline
GET /private/api/.../eventos
GET /private/api/.../auditoria
```

Também é importante diferenciar:

- logs técnicos: `print`, `debugPrint`, logs de request/response em services;
- eventos úteis ao usuário: venda realizada, produto alterado, pagamento recebido, atendimento atualizado.

Hoje existem eventos úteis espalhados por domínio, mas não uma fonte única para timeline operacional da Home.

## 16. Viabilidade de Sidebar esquerda

Uma Sidebar esquerda retrátil é tecnicamente viável, mas não deve ser implementada como simples substituição visual de `TopNavigationBarWeb`.

Impactos identificados:

- `TopNavigationBarWeb` hoje contém a árvore de navegação efetiva.
- Ele também contém ações concretas de abertura de módulo e overlays.
- `PaginaPrincipalWeb` contém parte da navegação por `_moduloAtual`.
- Vários módulos não possuem rotas próprias.
- Permissões não estão acopladas ao menu atual.

Arquivos diretamente impactados em uma futura implementação:

- `lib/top_navigation_bar_web.dart`;
- `lib/pagina_principal_web.dart`;
- `lib/main.dart`, somente se novas rotas forem criadas;
- telas Web de módulo usadas pelo menu;
- provider de permissões;
- novos arquivos de navegação/layout, se criados.

Componentes que poderiam ser reutilizados:

- ações e callbacks atuais de `PaginaPrincipalWeb`;
- telas embedded atuais;
- `AdminNavigationShell` como referência conceitual de sidebar/drawer, não como componente direto do app principal;
- `web_dashboard_widgets.dart` para a futura Home.

Responsivo:

- Em desktop largo, Sidebar expandida é adequada.
- Em notebook, Sidebar recolhida ajuda a preservar área útil.
- Em largura compacta de navegador Web, há duas opções: rail recolhido ou drawer Web. Isso deve ser tratado como Web responsivo, sem acionar fluxo mobile nativo.

Risco de regressão:

- Médio/alto se a troca mexer direto em `TopNavigationBarWeb` e `PaginaPrincipalWeb`.
- Médio se for criada antes uma definição central de navegação.
- Baixo para backend, desde que endpoints e services sejam preservados.

## 17. Viabilidade de um WebShell

Não encontrei um shell central autenticado do app principal com nome ou papel equivalente a:

```text
WebShell
MainLayout
AuthenticatedLayout
DashboardLayout
WebScaffold
AppLayout
```

Busca realizada em `lib` por esses termos, além de `NavigationRail`, `Drawer`, `Sidebar` e `Breadcrumb`.

Encontrado:

- `WebAuthShell`: usado para autenticação, não para app autenticado.
- `AdminNavigationShell`: usado para área admin, com sidebar/drawer.
- `PaginaPrincipalWeb`: funciona como shell prático do app principal, mas mistura layout, navegação, PDV, notificações e módulos.

Conceitualmente, faz sentido introduzir futuramente um shell Web autenticado:

```text
AuthenticatedWebShell
├── Sidebar / Rail
├── Header
│   ├── contexto de empresa
│   ├── busca/atalhos opcionais
│   ├── notificações
│   ├── IA
│   └── usuário/logout
└── Content
    └── página ou módulo atual
```

Esse shell deve ser criado de forma incremental, preservando `/app` e os módulos existentes. O primeiro passo recomendado não é redesenhar tudo; é separar a definição da navegação da renderização do menu.

## 18. Impacto estimado da mudança

### Baixo impacto

- Criar relatório e planejamento.
- Criar um registry de navegação Web sem alterar UI.
- Mapear permissões por item de navegação.
- Reaproveitar services existentes para protótipo interno de Home.

### Médio impacto

- Extrair header/notificações/logout de `PaginaPrincipalWeb` para um shell Web.
- Fazer `TopNavigationBarWeb` e uma futura Sidebar consumirem a mesma definição de navegação.
- Adaptar ações rápidas da Home para callbacks existentes.
- Usar dados reais na Home por composição de services existentes.

### Alto impacto

- Trocar menu superior por Sidebar em produção sem etapa intermediária.
- Transformar todos os módulos em rotas nomeadas profundas.
- Criar timeline global sem endpoint backend.
- Centralizar regras de atenção apenas no frontend chamando muitas listas.

### Impacto em backend

Não é obrigatório para uma primeira experiência, mas é recomendado para uma Home robusta:

- endpoint agregado de workspace/home;
- endpoint de atividade recente;
- agregações de atenção por comércio e permissão.

### Impacto em Mobile

Pode ser baixo se a alteração ficar restrita a:

- arquivos Web;
- nova camada de navegação Web;
- providers/services compartilhados sem alterar contrato;
- nenhuma alteração em `MobileMainShell`, `NavBarMobile` e telas mobile.

## 19. Riscos de regressão

- Confundir `DashboardInicioWeb` atual com fonte real de dados, quando hoje ele usa mock.
- Quebrar navegação porque `TopNavigationBarWeb` é menu e controlador de abertura de overlays ao mesmo tempo.
- Criar Sidebar duplicando a árvore de menu e deixando menu superior/sidebar divergirem.
- Mostrar itens financeiros para colaboradores sem permissão, já que o menu atual não filtra permissões.
- Fazer Home consultar muitas listas completas e prejudicar performance.
- Duplicar regras de atenção dentro de widgets.
- Misturar dados de comércios se uma futura troca multiempresa for adicionada sem atualizar `AuthService`, headers e providers.
- Perder deep link porque vários módulos hoje não possuem rota própria.
- Afetar Mobile se componentes visuais forem compartilhados indevidamente.
- Manter hardcode de `R$`, `pt_BR` e textos fixos em uma nova Home.
- Aumentar dívida técnica de `embedded: true` se isso virar padrão para todas as novas páginas.
- Usar eventos WebSocket em memória como se fossem histórico persistente.

Risco adicional encontrado: alguns services, como `ProdutoService`, fazem logs de request/response e headers. Isso não bloqueia a Home, mas deve ser revisto separadamente para evitar ruído ou exposição indevida em produção.

## 20. O que pode ser reaproveitado

Camadas reutilizáveis:

- `AuthService`;
- `EmpresaService`;
- `UsuarioService`;
- `ColaboradorAutorizacoesProvider`;
- `LocaleSettingsProvider`;
- `AtendimentoTecnicoService`;
- `AgendaFinanceiraLancamentoService`;
- `AgendaFinanceiraAcoesFinanceiras`;
- `CaixaService` e `CaixaApiClient`;
- `ProdutoService`;
- `VendaNaoLiquidadaApiClient`;
- `CatalogHealthApiClient`;
- models de atendimento técnico, agenda, caixa, produto, estoque e tela inicial.

Componentes/telas reutilizáveis:

- `DashboardInicioModel`, como contrato visual inicial, desde que conectado a dados reais;
- `web_dashboard_widgets.dart`;
- `SixBackendLoading`;
- `AtendimentosTecnicosListaWebPage`;
- `AtendimentosTecnicosWebPage`;
- `OperacoesCaixaWebPage`;
- `AgendaFinanceiraWeb`;
- `ProdutoDashboardWebPage`;
- `EstoqueDashboardWebPage`;
- `ServicoDashboardWebPage`;
- `ClientesUsuarioListPage`;
- `ColaboradoresUsuarioListPage`;
- `CategoriasProdutosServicosWebPage`.

Regras reutilizáveis com ajuste:

- `_entregaAtrasada()` de `AtendimentosTecnicosListaWebPage`, mas deve sair da tela se for usada pela Home.
- status financeiros de `AgendaFinanceiraWeb`.
- regra de caixa aberto de `OperacoesCaixaWebPage`.
- contadores de estoque vindos do backend.
- preferências de filtros em `UsuarioService`, caso a Home venha a ter preferências próprias.

## 21. O que realmente precisaria ser criado

Para uma evolução sustentável:

- definição central de navegação Web;
- permission predicates por item de navegação;
- `AuthenticatedWebShell` ou equivalente;
- Sidebar/Rail Web usando a definição central de navegação;
- provider/repository da Home Web com dados reais;
- adaptação do `DashboardInicioWeb` para consumir fonte real ou criação de nova `HomeWorkspaceWebPage`;
- camada de agregação para "Precisa da sua atenção";
- preferência individual opcional para estado da Sidebar e talvez último workspace;
- endpoint backend agregado de workspace/home, se a equipe quiser evitar múltiplas chamadas e regras duplicadas;
- endpoint ou consulta agregada de atividade recente, se timeline entrar no escopo.

Não parece necessário:

- reescrever os módulos atuais;
- alterar contratos existentes imediatamente;
- mexer no Mobile;
- criar uma landing page;
- substituir todos os overlays por rotas no primeiro passo.

## 22. Arquivos potencialmente envolvidos

Arquivos existentes que provavelmente seriam tocados em uma implementação futura:

```text
lib/main.dart
lib/pagina_principal_web.dart
lib/top_navigation_bar_web.dart
lib/presentation/components/dashboard_inicio_web.dart
lib/providers/dashboard_inicio_provider.dart
lib/data/models/dashboard_inicio_model.dart
lib/data/mock/dashboard_inicio_mock.dart
lib/presentation/components/web_dashboard_widgets.dart
lib/presentation/components/web_auth_shell.dart
lib/presentation/admin/admin_navigation_shell.dart
lib/presentation/screens/post_login_splash_web_page.dart
lib/domain/services/auth_service.dart
lib/domain/services/telainicial_web/tela_inicial_web_service.dart
lib/data/services/telainicial_web/tela_inicial_api_client.dart
lib/data/models/tela_inicial_models.dart
lib/providers/colaborador_autorizacoes_provider.dart
lib/data/models/colaborador_autorizacoes_model.dart
lib/domain/services/usuario_service.dart
lib/data/models/usuario_model.dart
lib/providers/empresa_provider.dart
lib/domain/services/empresa_service.dart
lib/presentation/screens/atendimentos_tecnicos_web_page.dart
lib/presentation/screens/atendimentos_tecnicos_lista_web_page.dart
lib/data/services/atendimento_tecnico_api_client.dart
lib/domain/services/atendimento_tecnico_service.dart
lib/presentation/screens/agenda_financeira_web.dart
lib/data/services/agenda_financeira_lancamento_service.dart
lib/presentation/screens/operacoes_caixa_web_page.dart
lib/data/services/caixa_api_client.dart
lib/presentation/screens/produto_dashboard_web_page.dart
lib/presentation/screens/estoque_dashboard_web_page.dart
lib/domain/services/produto_service.dart
lib/services/websocket_service.dart
lib/services/notificacao_service.dart
```

Arquivos novos conceituais possíveis:

```text
lib/presentation/layouts/authenticated_web_shell.dart
lib/presentation/navigation/web_navigation_registry.dart
lib/presentation/navigation/web_navigation_item.dart
lib/presentation/components/web_sidebar_navigation.dart
lib/presentation/screens/home_workspace_web_page.dart
lib/providers/web_workspace_home_provider.dart
lib/data/services/web_workspace_home_api_client.dart
lib/data/models/web_workspace_home_model.dart
```

Esses nomes são apenas sugestão arquitetural. Não foram criados nesta investigação.

## 23. Recomendação arquitetural

Recomendação de menor risco:

1. Preservar `/app` como entrada pós-login.
2. Criar uma definição central de navegação Web, inicialmente consumida pelo menu superior atual.
3. Associar permissões a cada item dessa definição, usando `ColaboradorAutorizacoesProvider`.
4. Introduzir um `AuthenticatedWebShell` de forma incremental, mantendo `PaginaPrincipalWeb` funcionando.
5. Mover header, notificações, IA e logout para o shell quando a separação estiver clara.
6. Criar uma Home Web real como workspace operacional, sem aparência de landing page.
7. Conectar a Home primeiro a services existentes, com cuidado para não chamar listas pesadas sem necessidade.
8. Definir com backend um endpoint agregado para versão madura da Home.
9. Implementar a Sidebar usando a mesma definição central de navegação.
10. Só depois avaliar rotas nomeadas profundas para os módulos mais usados.

Estratégia recomendada para a Home:

- usar `LocaleSettingsProvider` desde o início para moedas/datas;
- esconder KPIs e ações conforme permissões;
- respeitar `idUnicoDaEmpresa` atual;
- separar visual Web de Mobile;
- usar `SixBackendLoading` para carregamento;
- reaproveitar dashboards existentes como fonte de padrão visual, não como widgets inteiros dentro da Home.

Branch sugerida:

```text
feature/web-workspace-home-sidebar
```

## 24. Perguntas que ainda precisam de decisão de produto

- A primeira tela pós-login deve ser sempre a Home ou deve respeitar último módulo usado?
- ADMIN e colaborador devem ver a mesma Home com filtros por permissão ou experiências diferentes?
- Colaborador sem financeiro deve ver valores ocultos, cards removidos ou mensagens de sem acesso?
- O ADMIN precisa trocar comércio dentro da Web? Se sim, onde esse seletor deve ficar?
- A Home deve representar apenas o comércio atual ou consolidar múltiplos comércios para ADMIN?
- Quais status oficiais significam "aguardando cliente", "pronto para entrega" e "orçamento aguardando aprovação"?
- Timeline de atividade recente entra na primeira versão ou fica para etapa posterior?
- Itens de menu preparatórios devem continuar visíveis, ficar marcados como em breve ou desaparecer até estarem prontos?
- A Sidebar deve ter busca global de módulos?
- O estado recolhido/expandido da Sidebar deve ser preferência individual?
- A Home deve ter atalhos configuráveis por usuário?
- A futura navegação deve priorizar rotas nomeadas/deep links ou manter módulos internos inicialmente?
- Qual é o limite aceitável de chamadas backend no carregamento inicial da Home?
- O backend deve entregar um único endpoint `/workspace`/`home` agregado?
- Quais dados são sensíveis o suficiente para exigir permissão específica antes mesmo de consultar o backend?
