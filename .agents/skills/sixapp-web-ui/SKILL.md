---
name: sixapp-web-ui
description: Use ao criar, reformular ou revisar interfaces Flutter Web do SixApp, incluindo telas desktop, subpainéis, formulários Web, dashboards, tabelas, filtros, modais, menus, cards, navegação, responsividade de navegador e modernização visual. Acione também quando a mudança Web envolver textos, moedas, datas, números, percentuais, mensagens ou configurações vindas do backend para combinar com `sixapp-regionalization`. Não use para tarefas exclusivamente mobile, backend puro, integrações sem impacto visual, banco de dados, refatorações técnicas sem UI ou documentação administrativa.
---

# UI Web do SixApp

Use esta Skill para manter a experiência Flutter Web do SixApp consistente com o Design System real do projeto e semanticamente alinhada com Mobile e backend.

Quando a alteração Web também envolver textos, moeda, datas, números, percentuais ou configurações do comércio, use também `sixapp-regionalization`. Quando envolver endpoint, contrato, parsing, autenticação, tenant, service ou ApiClient compartilhado, use também `sixapp-shared-backend-integration`.

## Leituras Mínimas

Para tarefa visual Web, leia:

- `AGENTS.md`;
- `.junie/AGENTS.md`, se existir no workspace;
- a tela, componente ou subpainel alvo;
- providers, controllers, services, DTOs e clients consumidos pelo fluxo;
- uma ou duas implementações Web semelhantes;
- `references/web-design-system.md`.

Leia `sixapp-regionalization/references/frontend-localization.md` e `sixapp-regionalization/references/backend-configuration-contract.md` quando houver conteúdo de usuário, i18n, moeda, data, hora, número, percentual, medidas ou configuração do backend.

## Fluxo Obrigatório

1. Identifique se o escopo é Web, Mobile ou compartilhado.
2. Leia o arquivo citado pelo usuário e localize componentes, controllers/providers e services relacionados.
3. Inspecione implementações semelhantes antes de criar componente, layout ou padrão novo.
4. Verifique padrões visuais existentes de cores, tipografia, espaçamento, elevação, bordas, ícones, estados e motion.
5. Mapeie textos e dados regionalizáveis afetados.
6. Verifique endpoint, contrato, DTO/modelo, service e persistência quando o conteúdo vier do backend ou precisar ser configurável.
7. Classifique conteúdos com `sixapp-regionalization`: texto estático, texto configurável por tenant, texto/mensagem dinâmica de domínio ou dado regionalizável.
8. Defina impacto em Web, Mobile, código compartilhado, backend, persistência, traduções e testes.
9. Apresente plano curto antes da implementação quando houver impacto relevante em mais de uma camada.
10. Implemente a mudança completa dentro do escopo, sem transformar ajuste visual em refatoração ampla.
11. Valide formatação, análise estática, testes aplicáveis e diff.
12. Informe claramente o que foi alterado em cada camada.

## Escopo Web

Para pedidos somente Web:

- preserve arquivos `*_mobile_screen.dart` e `lib/presentation/components/mobile/`;
- não altere `SixMobilePalette`, `SixMobilePageShell`, `SixMobileTypography`, `NavBarMobile` ou `mobile_motion.dart`;
- não copie literalmente padrões mobile para desktop;
- não altere tema global, `main.dart` ou providers compartilhados sem necessidade técnica comprovada;
- quando código compartilhado ou backend forem indispensáveis, explique o impacto antes de editar.

Para pedidos compartilhados, telas Web e Mobile podem ter composições diferentes, mas devem reutilizar a mesma regra de negócio, client, DTO/modelo, mapper, service e interpretação de resposta sempre que consumirem o mesmo recurso.

## Design System Web

Use `Theme.of(context).colorScheme`, `AppTheme`, `SixThemeResolver` e componentes Web existentes antes de introduzir cores, raios, sombras ou padrões locais. Preserve compatibilidade com aparências configuráveis pelo comércio.

Procure primeiro por:

- `SixWebDashboardHeader`, `SixWebEntry`, `SixWebKpiCard`, `SixWebSectionCard`, `SixWebNoData` e `SixWebLoadingBlock`;
- `SixBackendLoading` para carregamento de mensagens, eventos ou configurações do backend;
- `AppModalSideSheet` para painéis laterais responsivos;
- `SubPainelWebGeneral` e subpainéis existentes para fluxos modais Web;
- telas recentes equivalentes de configuração, catálogo, dashboard e atendimento.

Evite listas cruas com `ListTile` simples em subpainéis importantes. Prefira card superior de contexto, área organizada de busca/filtros, cards compactos com hierarquia clara e barra inferior discreta para contagem, atualização e ações secundárias.

## Responsividade E Estados

Valide mentalmente desktop largo, notebook, tablet e largura compacta. Use `LayoutBuilder`, `Wrap`, `Expanded`, `Flexible`, `ConstrainedBox`, `SingleChildScrollView`, `GridView` responsivo e `TextOverflow.ellipsis` para impedir overflow em português, inglês e espanhol.

Trate carregamento, vazio, erro, sucesso, bloqueio e falta de permissão. Em telas dependentes do backend, prefira skeleton estrutural ou `SixBackendLoading` a spinner central quando a estrutura da tela já for conhecida.

Use motion funcional e curto: entrada progressiva com `fade + leve deslocamento`, `AnimatedSwitcher`, `TweenAnimationBuilder`, `AnimatedContainer`, `FadeTransition` ou `SlideTransition`. Dashboards e gráficos podem animar entrada e atualização; evite animação contínua decorativa.

## Formulários, Tabelas E Filtros

Formulários Web devem preservar leitura, validação clara, labels/placeholder via i18n quando forem texto do app, botões proporcionais e layout que degrade bem em largura compacta.

Para dropdowns/selects Web em formulários, filtros e barras de ação importantes, prefira o padrão visual elegante já usado na navegação de `pagina_principal_web.dart`/`TopNavigationBarWeb`: campo clicável com `InkWell` + `AnimatedContainer`, `showMenu`, cantos de 16-18, borda sutil, estado hover/aberto, chevron animado e itens `PopupMenuItem` customizados com ícone ou check do selecionado. Evite `DropdownButtonFormField` cru quando ele deixar o subpainel com aparência genérica; se o padrão se repetir em mais de uma tela, extraia para componente Web reutilizável mantendo labels, tooltip, vazio/erro/desabilitado e responsividade via i18n.

Tabelas, filtros e listas devem favorecer escaneabilidade: busca e filtros agrupados, chips discretos de metadados, ações alinhadas, valores importantes em blocos compactos e layout alternativo em telas estreitas.

Modais e side sheets devem preservar foco, escape/fechamento previsível, tamanho responsivo, conteúdo rolável, botões acessíveis e estados de envio/erro.

## Acessibilidade E Internacionalização

Preserve contraste, foco de teclado, ordem de leitura, `tooltip`/labels em ações de ícone, semântica de estado e suporte a texto longo.

Não deixe novas strings visíveis espalhadas em widgets. Use o mecanismo de internacionalização atual do projeto e classifique o conteúdo com `sixapp-regionalization` antes de decidir se ele pertence ao frontend, backend ou payload configurável.

Não hardcode `R$`, `BRL`, `pt_BR`, separador decimal, data `dd/MM/yyyy`, timezone brasileiro ou percentuais formatados manualmente em UI Web. Use `LocaleSettingsProvider` ou helper centralizado que delegue para ele.

## Proibições

Nunca, em tarefa visual Web:

- duplicar client HTTP, request, response, parser, mapper ou service;
- adaptar payload diretamente na tela;
- mover regra de negócio para widget;
- introduzir novo gerenciador de estado sem autorização;
- modificar autenticação, tenant, permissões ou contratos sem relação direta com o pedido;
- alterar fluxo mobile quando o pedido disser somente Web;
- consolidar como regra permanente um hash de commit, arquivo temporário ou workaround recente sem validar contra a arquitetura.
