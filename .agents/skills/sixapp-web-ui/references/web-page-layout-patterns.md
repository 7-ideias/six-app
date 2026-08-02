# Padrões De Estrutura Superior Web

Esta referência formaliza o padrão preferencial para o topo de páginas, modais e side sheets Web do SixApp. A fonte de verdade visual é o código atual e estável da tela Web `Produtos`, especialmente:

- `lib/presentation/screens/produto_dashboard_web_page.dart`;
- `lib/presentation/components/web_dashboard_widgets.dart`;
- usos consolidados de `SixWebDashboardHeader` em dashboards Web recentes, como estoque e serviços.

A imagem de `Produtos` pode orientar a leitura visual inicial, mas a regra deve ser confirmada no código antes de modificar outra tela. Não registre nem copie valores numéricos frágeis quando houver token, tema ou componente equivalente no projeto.

## Referência Oficial

A tela Web `Produtos` representa o padrão preferencial para a estrutura superior de páginas e modais Web do SixApp.

Essa referência não significa copiar literalmente os cards, indicadores, listas ou gráficos da tela. Significa reaproveitar sua linguagem visual: superfície clara, cabeçalho integrado ao contêiner, ícone contextual em superfície suave, título com hierarquia clara, subtítulo curto, ações contextuais agrupadas à direita, botão primário destacado na cor principal, botões secundários discretos, fechamento evidente, divisória sutil quando necessária e conteúdo ocupando bem a largura disponível.

Antes de criar, atualizar ou refatorar uma página Web, inspecione a implementação atual de `Produtos` e os componentes compartilhados ligados a ela. Use o padrão vigente do código, não uma memória antiga da tela.

## Anatomia Do Cabeçalho

O cabeçalho principal deve ser único e integrado à página, modal ou side sheet. Ele deve conter, quando fizer sentido para o fluxo:

- superfície principal clara, normalmente derivada de `Theme.of(context).colorScheme`;
- ícone contextual dentro de uma superfície suave, sem bloco pesado ou decorativo demais;
- título principal único, direto e semanticamente correto;
- subtítulo curto explicando a finalidade da página ou o estado do registro;
- ações contextuais agrupadas à direita no desktop e com quebra organizada em larguras menores;
- ação primária com destaque na cor principal do SixApp;
- ações secundárias com tratamento discreto, como `OutlinedButton`, botão tonal ou ícone com tooltip;
- botão de fechamento, voltar ou cancelar claramente identificável quando o fluxo exigir;
- divisória sutil entre cabeçalho e conteúdo quando houver mudança de área;
- alinhamentos, margens, espaçamentos, raios e proporções coerentes com componentes Web existentes;
- `Expanded`, `Wrap`, `TextOverflow.ellipsis` e limites responsivos para suportar textos em português, inglês e espanhol.

## Adaptação Por Tipo De Página

Dashboard, resumo ou listagem:

- pode ter `Atualizar`, criar novo registro, abrir lista completa, filtros ou ações complementares;
- pode combinar cabeçalho com KPIs, gráficos, alertas ou lista compacta abaixo;
- deve priorizar ações de leitura, atualização e exploração de dados.

Cadastro:

- use título como `Novo produto`, `Cadastro de produto` ou equivalente do domínio;
- mantenha descrição curta sobre a finalidade do cadastro;
- apresente `Cancelar`, `Fechar`, `Salvar`, `Continuar` ou `Concluir`, conforme a jornada;
- não apresente ações de dashboard que não façam sentido no cadastro, como atualizar resumo, abrir lista completa ou filtros executivos;
- não adicione banner hero antes do formulário se o cabeçalho principal já explica a página.

Edição:

- use título com contexto do registro, quando disponível;
- apresente descrição curta, status relevante ou orientação de revisão;
- preserve `Cancelar` ou `Fechar` e `Salvar alterações`;
- inclua ações secundárias apenas quando forem necessárias ao domínio e às permissões do usuário.

Visualização:

- pode apresentar `Voltar` ou `Fechar`;
- pode expor `Editar`, `Imprimir`, `Compartilhar` ou ações pertinentes ao domínio;
- deve evitar transformar a área superior em dashboard se o objetivo da página for consulta de um registro.

## Ações

As ações devem representar a jornada real da página, não um conjunto genérico de botões. Prefira:

- ação primária única e evidente;
- ações secundárias discretas e proporcionais;
- agrupamento em `Wrap` para evitar overflow;
- `tooltip` em ações de ícone;
- estado desabilitado, loading e erro preservados;
- permissões existentes respeitadas antes de exibir ação sensível.

Não duplique a mesma ação em barra superior, banner e rodapé sem necessidade. Se houver rodapé fixo ou barra inferior de formulário, ele deve complementar o cabeçalho, não repetir hierarquia de página.

## Padrão Proibido

Evite cabeçalhos empilhados e dupla hierarquia de página.

Uma página, modal ou side sheet Web não deve possuir simultaneamente:

1. uma barra superior independente com título, voltar e fechar; e
2. um segundo banner ou hero repetindo ícone, título e contexto.

A tela atual `Cadastro de Produtos` em `lib/sub_painel_cadastro_produto_web.dart` é exemplo de divergência que não deve ser replicada como padrão: `SubPainelWebGeneral` cria uma `AppBar` com título/fechamento e o body cria outro `_buildHeader` em banner degradê, repetindo título e contexto antes do formulário. Esse formato cria excesso de destaque, duplicação de retorno/fechamento e quebra a continuidade visual entre cabeçalho e conteúdo.

Ao ajustar uma tela nessa situação, consolide a hierarquia em um único cabeçalho principal alinhado ao padrão de `Produtos`, preservando rotas, permissões, validações, envio, estados e integrações existentes.

## Reutilização

Antes de implementar uma página Web:

- procure componentes, tokens, temas e widgets usados pela tela Web `Produtos`;
- considere `SixWebDashboardHeader`, `SixWebEntry`, `SixWebKpiCard`, `SixWebSectionCard`, `SixWebNoData`, `SixWebLoadingBlock`, `AppModalSideSheet` e padrões locais do fluxo;
- reutilize ou evolua abstrações existentes antes de criar estilos locais;
- evite criar cores, espaçamentos, raios, sombras e estilos tipográficos isolados;
- proponha extração de componente compartilhado quando houver repetição real;
- preserve comportamentos funcionais, permissões, rotas, validações, contratos e integrações.

Se ainda não houver um componente compartilhado adequado para determinada variação, avalie a criação futura de uma abstração equivalente a `Web Page Header` ou `Web Modal Header`. Não force abstração prematura quando as telas tiverem necessidades semânticas diferentes.

## Responsividade

O cabeçalho e o conteúdo devem funcionar em desktop largo, notebook e largura compacta de navegador.

Use composição responsiva em vez de largura fixa rígida:

- `LayoutBuilder` para decidir quebras;
- `Wrap` para ações e metadados;
- `Expanded` e `Flexible` para título e subtítulo;
- `ConstrainedBox` para largura máxima de conteúdo;
- `SingleChildScrollView` quando o corpo precisar rolar;
- `TextOverflow.ellipsis` e `maxLines` para strings longas.

A ação principal pode ir abaixo do texto em largura compacta, desde que a hierarquia continue clara e sem overflow.

## Checklist Obrigatório

Antes de finalizar qualquer página, modal ou side sheet Web:

- existe apenas um cabeçalho principal?
- título, contexto, voltar, fechar ou ação principal estão duplicados?
- o cabeçalho segue a hierarquia visual da tela Web `Produtos`?
- as ações são pertinentes ao tipo da página?
- componentes, temas e tokens existentes foram reutilizados?
- a página funciona em larguras menores sem overflow?
- textos estão internacionalizados ou vêm das configurações/backend quando aplicável?
- estados de carregamento, vazio, erro, sucesso e bloqueio foram considerados?
- navegação por teclado, foco, contraste, tooltip e acessibilidade foram preservados?
- nenhuma regra funcional, permissão, rota, validação ou contrato foi alterado apenas para atender ao layout?
