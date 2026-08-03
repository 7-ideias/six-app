# Design System Web do SixApp

Esta referência resume padrões Web identificados no código atual e nas decisões recorrentes dos commits Web recentes. Não transforme hashes, workarounds ou arquivos temporários em regra permanente; valide sempre contra a arquitetura atual.

## Componentes reutilizáveis

- `lib/presentation/components/web_dashboard_widgets.dart`
  - `SixWebDashboardHeader`: cabeçalho de dashboard/subpainel com título, subtítulo e ações.
  - `SixWebEntry`: entrada com fade e leve deslocamento.
  - `SixWebKpiCard`: KPI com ícone, valor, subtitle, tendência e animação.
  - `SixWebSectionCard`: seção Web com borda, sombra leve e header.
  - `SixWebNoData`: estado vazio de dashboard.
  - `SixWebLoadingBlock`: skeleton simples por bloco.
- `lib/presentation/components/six_backend_loading.dart`
  - Use para mensagens, eventos e configurações carregadas do backend.
  - Preferir `skeletonPulse` em telas executivas, `waveDots` em cards compactos e `progressSweep` para sincronização linear.
- `lib/presentation/components/app_modal_side_sheet.dart`
  - Use para painel lateral responsivo com Escape, foco, largura controlada e conteúdo rolável.
- `lib/design_system/components/web/sub_painel_web_general.dart`
  - Use como referência de subpainel Web existente quando a tela já estiver nesse fluxo.
- `lib/presentation/screens/formas_recebimento_configuracao_content.dart`
  - Boa referência recente de configuração Web: resumo superior, cards compactos, skeleton, erro/vazio, barra inferior e dialog de edição.
- `lib/presentation/screens/produto_dashboard_web_page.dart`
  - Referência preferencial para a estrutura superior de páginas e modais Web, além de boa referência de dashboard e gráficos animados, com interação por hover/toque e chaves estáveis.
- `lib/presentation/screens/regionalizacao_configuracao_content.dart`
  - Boa referência de configuração regional: provider global, codes técnicos, preview, skeleton e `context.t`.

## Tokens e convenções visuais

- Use `Theme.of(context).colorScheme` como fonte inicial de cor Web.
- Preserve `AppTheme` e `SixThemeResolver` como infraestrutura compartilhada; mudanças neles podem afetar Web, Mobile e aparência por comércio.
- Use bordas sutis com `colorScheme.outlineVariant` ou opacidade baixa do outline.
- Use sombras leves, geralmente opacidade baixa, blur curto/médio e offset pequeno.
- Use raios consistentes com o projeto: tema global usa 12 em cards/inputs; telas Web recentes usam 16 a 24 em painéis e cards destacados.
- Prefira `FilledButton`, `OutlinedButton`, `IconButton` e chips com proporção contida.
- Ícones de ações devem ter `tooltip` e tamanho visual compatível com cards compactos.
- `WebRootTokens` e `WebRootScheme` pertencem ao root/landing Web; não generalize esses tokens para telas internas de gestão sem avaliar contexto.
- `AppTextStylesWeb` e `AppCard` existem, mas não são um design system rico. Não os trate como única fonte de verdade.

## Layout Web

Para estrutura superior de páginas, modais e side sheets Web, leia também `references/web-page-layout-patterns.md`. A tela Web `Produtos` deve orientar a linguagem visual do cabeçalho principal: superfície clara, ícone contextual em bloco suave, título único, subtítulo curto, ações agrupadas à direita, primária em destaque, secundárias discretas e fechamento claro.

Padrão recorrente para subpainéis e listagens importantes:

1. Cabeçalho ou card superior de contexto/resumo.
2. Busca e filtros agrupados em área organizada.
3. Conteúdo principal em cards compactos, tabela responsiva ou grid conforme densidade dos dados.
4. Ação principal alinhada à direita no desktop e reposicionada em largura compacta.
5. Barra inferior discreta para contagem, atualização, limpar filtros ou ações secundárias.

Use `LayoutBuilder`, `Wrap`, `ConstrainedBox`, `Expanded`, `Flexible`, `SingleChildScrollView`, grids responsivos e `TextOverflow.ellipsis`. Não assuma largura infinita.

Breakpoints observados em telas Web recentes variam conforme contexto: 520, 560, 720, 760, 820, 860, 980, 1180 e 1320. Para landing/root, os tokens usam 768 e 1024. Use o breakpoint local que corresponda ao conteúdo, evitando criar constante global sem padrão consolidado.

## Formulários

- Agrupe campos por propósito, com hierarquia visual clara e espaçamento previsível.
- Em desktop, use duas colunas quando os campos forem compatíveis; em largura compacta, degrade para uma coluna.
- Preserve validações simples no frontend quando melhorarem a experiência.
- Use labels, placeholders e mensagens via i18n quando forem textos estáticos do app.
- Não instancie service/client dentro do widget quando houver provider/service reutilizável mais apropriado.
- Evite adaptar payload diretamente na tela; use model, mapper, service ou provider compartilhado.

## Tabelas, filtros e listas

- Use filtros com `Wrap` para evitar overflow.
- Metadados devem aparecer em chips discretos.
- Valores importantes podem ir em blocos pequenos, não em cards enormes sem hierarquia.
- Cards de listagem devem ter título forte, subtítulo/metadados, estado visual e ação principal proporcional.
- Em largura compacta, permita quebra organizada da ação e dos metadados.
- Evite `ListTile` cru para subpainel Web importante.

## Estados, loading e motion

- Trate loading, vazio, erro, sucesso, bloqueio e falta de permissão.
- Use skeleton estrutural quando a tela já conhece o formato dos dados.
- Use `SixBackendLoading` para mensagens/configurações/eventos do backend.
- Use `AnimatedSwitcher` para troca de estado.
- Use `SixWebEntry` ou `FadeTransition` + `SlideTransition` para entrada curta por prioridade.
- KPIs e números executivos podem usar `TweenAnimationBuilder` com chave estável baseada no valor.
- Em gráficos `fl_chart`, use crescimento/revelação na entrada e interação isolada por gráfico com estado de hover/toque próprio.
- Evite animação contínua em dashboard executivo.

## Regionalização e i18n

Use `sixapp-regionalization` sempre que a tela exibir:

- texto novo;
- status/enum/código de domínio;
- mensagem de erro, sucesso, vazio ou validação;
- moeda, preço, saldo, total ou percentual;
- data, hora, número decimal ou medida;
- configuração retornada ou persistida pelo backend.

No código atual ainda existem telas Web com `R$`, `pt_BR`, strings fixas e formatadores locais. Trate isso como legado a corrigir quando o fluxo for tocado, não como padrão correto.

## Práticas a evitar

- Copiar visual mobile para Web ou Web para mobile sem adaptar a experiência.
- Criar cores hexadecimais locais quando `ColorScheme` ou token existente resolver.
- Criar card grande genérico com sombra pesada para lista densa.
- Usar spinner central genérico quando skeleton ou estrutura final for conhecida.
- Duplicar client, DTO, mapper, service ou parsing entre Web e Mobile.
- Transformar modernização visual pontual em refatoração ampla.
- Criar cabeçalhos empilhados, com uma barra superior independente e um segundo banner/hero repetindo título, ícone, retorno ou fechamento.
- Alterar permissões, tenant, autenticação ou contrato apenas por layout.
- Persistir labels traduzidos no backend em vez de códigos técnicos.
