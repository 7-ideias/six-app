---
name: sixapp-mobile-ui
description: Use ao criar, reformular ou revisar interfaces Flutter mobile do SixApp, especialmente telas `*_mobile_screen.dart`, componentes em `lib/presentation/components/mobile/`, AppBar mobile, cards, estados vazios, FABs, botões, navegação mobile, seletores/dropdowns mobile, bottom sheets, Lottie, motion, contraste, status bar, acessibilidade e consistência com `SixMobilePalette`, `SixMobilePageShell` e `NavBarMobile`. Acione também quando telas mobile envolverem textos, moedas, datas, números, percentuais, mensagens ou configurações do backend para combinar com `sixapp-regionalization`. Não use para tarefas exclusivamente backend, integrações de API sem mudança visual, mudanças apenas no Flutter Web, regras de negócio sem impacto de UI, banco de dados, refatorações técnicas puras ou documentação administrativa.
---

# UI mobile do SixApp

Use esta Skill para manter a experiência mobile Flutter do SixApp consistente, profissional e separada do Flutter Web.

Sempre garanta também a Skill `sixapp-mobile-colors` ao usar esta skill, mesmo quando o pedido parecer centrado em layout, composição, navegação ou componentes. Contraste, tokens semânticos, CTA em dark mode, superfícies e legibilidade fazem parte obrigatória da revisão de UI mobile.

Quando a tarefa visual mobile também envolver endpoint, contrato, parsing, autenticação, tenant, service ou ApiClient compartilhado, use também a Skill `sixapp-shared-backend-integration`. Esta Skill cuida da UI; a Skill de backend cuida da integração.

Regra arquitetural obrigatória: telas mobile não devem ser implementadas como wrapper de telas, formulários grandes, dashboards, modais ou conteúdos principais Web. É permitido reaproveitar chamadas ao backend, ApiClient, DTOs, mappers, services, models, providers/controladores sem responsabilidade visual e helpers de formatação. Não use `embedded`, `isMobile`, `isWeb`, `LayoutBuilder` ou condicionais equivalentes para transformar a mesma árvore visual em Web e Mobile.

Antes de qualquer ajuste, implementação ou refactor mobile, valide explicitamente se a mudança criaria ou manteria reaproveitamento indevido de UI entre Web e Mobile. Se encontrar tela/conteúdo principal compartilhado, wrapper, parâmetro `embedded`/`compact`/`platform`/`isMobile`/`isWeb` ou import cruzado de tela, trate como risco arquitetural e proponha composição mobile própria antes de editar.

Quando a tarefa envolver textos visíveis, moeda, data, hora, número, percentual, unidade, status, mensagens ou configurações do comércio, use também `sixapp-regionalization` para classificar o conteúdo e verificar impacto em frontend, contrato, backend, persistência, traduções e testes.

## Leituras mínimas

Para tarefa visual mobile, leia:

- `AGENTS.md`;
- `../sixapp-mobile-colors/SKILL.md`;
- `docs/ui/mobile-first-patterns.md`;
- `lib/design_system/themes/six_mobile_palette.dart`;
- `lib/presentation/components/mobile/six_mobile_page_shell.dart`;
- a tela ou componente alvo;
- a tela anterior do fluxo, para continuidade visual.

Leia `references/mobile-design-system.md` quando precisar consultar tokens, shell, motion, Lottie, separação mobile/web ou exemplos. Leia `references/current-mobile-patterns.md` para uma referência curta dos padrões móveis confirmados no projeto real. Use `references/implementation-checklist.md` como checklist antes de finalizar.

## Fluxo obrigatório

1. Classifique o escopo: mobile, web, compartilhado, visual, funcional ou visual com backend.
2. Garanta a aplicação de `sixapp-mobile-colors` junto da revisão de UI, auditando contraste, superfícies, estados, botões e CTAs inline no dark mode.
3. Se o pedido for somente mobile, preserve arquivos web e evite tema global.
4. Localize componentes, controllers/providers, services e implementações mobile semelhantes. Não use telas Web como base de composição; use-as apenas para entender regra de negócio, dados e cobertura funcional.
5. Antes de editar, valide se os arquivos-alvo importam, renderizam ou embrulham tela/conteúdo principal Web; se sim, separe a composição mobile em arquivo próprio e mantenha apenas integração/domínio compartilhados.
6. Mapeie textos e dados regionalizáveis afetados; use `sixapp-regionalization` para classificar conteúdos em estáticos, configuráveis por tenant, dinâmicos de domínio ou dados regionalizáveis.
7. Antes de editar, informe os arquivos que pretende alterar e por que são seguros para mobile.
8. Reutilize `SixMobilePalette`, `SixMobilePageShell`, `NavBarMobile` e componentes mobile existentes antes de criar padrões novos.
9. Em telas legadas migradas para o padrão mobile, revise também textos visíveis, moeda, números e datas para respeitar idioma e regionalização globais.
10. Implemente com escopo mínimo, sem alterar regras de negócio, contratos de API, autenticação, permissões ou fluxos web.
11. Valide com `dart format <arquivos>`, `git diff --check`, `git diff` e, quando aplicável, `flutter analyze` e testes relacionados.
12. No relato final, informe arquivos alterados, tokens usados, motion aplicado, acessibilidade, impacto de regionalização, validações e confirmação de ausência de impacto web e de wrapper UI Web/Mobile.

## Escopo mobile

Para alterações solicitadas somente no mobile:

- não modifique `PaginaPrincipalWeb`;
- não modifique arquivos `*_web.dart`, `*_web_page.dart` ou `*_web_dialog.dart`;
- não importe nem renderize telas/conteúdos Web dentro de telas Mobile;
- não crie conteúdo visual principal compartilhado entre Web e Mobile com parâmetro `embedded`, `compact`, `platform`, `isMobile` ou similar;
- não modifique `PdvVisualThemeResolver`;
- não altere `AppTheme`, `ThemeProvider`, `SixThemeResolver` ou `main.dart` sem necessidade técnica comprovada e autorização explícita;
- prefira arquivos `*_mobile_screen.dart`, `lib/presentation/components/mobile/`, `NavBarMobile`, `mobile_motion.dart` e tokens mobile.

## Design System mobile

`SixMobilePalette` é a fonte principal de cores mobile. Não use cor hardcoded quando existir token semântico equivalente.

Incorreto:

```dart
const Color(0xFF2563EB)
```

Correto:

```dart
SixMobilePalette.accent
```

Mesmo que o valor hexadecimal seja igual, use o token para preservar intenção semântica.

Para novos tokens, confirme que o uso é reutilizável, procure usos equivalentes, evite sinônimos visuais, nomeie por finalidade e prefira `SixMobilePalette` somente quando o conceito for realmente mobile e reutilizável. Para componente complexo e específico, considere tokens de componente derivados da paleta mobile.

## Estrutura e navegação

Para telas principais mobile com AppBar e corpo rolável, avalie primeiro `SixMobilePageShell`; ele já trata AppBar consistente, contraste automático, status bar, blur no scroll, fundo animado, `topInset` e integração com `NavBarMobile`.

Não use o shell cegamente. Se a tela exigir `Scaffold` próprio, justifique.

Use `MobileMainShell`, `NavBarMobile` e padrões existentes de navegação mobile. Não copie navegação web nem crie segunda bottom navigation sem necessidade comprovada.

## AppBar, status bar e contraste

Toda AppBar mobile deve manter contraste suficiente, ícones legíveis, `SafeArea`, status bar coerente e labels/semântica nas ações. Evite `foregroundColor: Colors.white` em AppBar transparente quando o fundo real for claro. Verifique se `SixMobilePageShell` já resolve o caso.

## Padrão oficial de cabeçalho mobile

O padrão visual prioritário para cabeçalhos mobile do SixApp é o implementado por meio de `SixMobilePageShell` e dos tokens de `SixMobilePalette`.

A tela mobile de “Balcão de venda” pode ser utilizada como referência visual atual para:

- integração entre status bar e cabeçalho;
- fundo escuro com gradiente;
- contraste de título, botão de retorno e ações;
- altura e espaçamento do cabeçalho;
- transição visual entre cabeçalho e conteúdo;
- tratamento de `SafeArea`;
- comportamento de blur e scroll, quando aplicável.

A tela de referência serve para compreensão do resultado esperado, mas não deve ser usada como fonte de cópia indiscriminada de código.

### Migração de telas antigas

Ao criar, revisar ou reformular uma tela mobile, verifique se o cabeçalho utiliza algum padrão legado, como:

- AppBar com cor sólida independente;
- azul hardcoded;
- gradiente definido diretamente na tela;
- status bar com cor desconectada do cabeçalho;
- título ou ícones com contraste inadequado;
- `Scaffold` e AppBar locais que duplicam recursos do `SixMobilePageShell`;
- implementação visual diferente sem justificativa funcional.

Quando encontrar um padrão legado:

1. localize a implementação atual da tela;
2. localize uma tela equivalente que já utilize `SixMobilePageShell`;
3. compare título, leading, actions, scroll, SafeArea e conteúdo inferior;
4. avalie a migração para `SixMobilePageShell`;
5. preserve todas as ações e comportamentos específicos da tela;
6. utilize tokens existentes de `SixMobilePalette`;
7. evite criar nova variação de cabeçalho;
8. mantenha o escopo restrito ao mobile;
9. não altere regra de negócio, navegação, integração ou estado funcional;
10. informe no plano quais elementos serão preservados e quais serão padronizados.

Se a tela não puder utilizar `SixMobilePageShell`, documente tecnicamente o motivo antes de implementar um `Scaffold` próprio.

### Fonte única do padrão visual

Gradiente, cores, contraste, status bar, blur, espaçamentos e comportamento de scroll devem vir preferencialmente de:

- `SixMobilePageShell`;
- `SixMobilePalette`;
- componentes em `lib/presentation/components/mobile/`;
- tokens ou abstrações já existentes no design system mobile.

É proibido criar, diretamente em uma tela, um gradiente visualmente semelhante ao padrão oficial utilizando novos valores hardcoded.

Mesmo quando a aparência final for igual, a implementação deve reutilizar a fonte oficial para que alterações futuras sejam propagadas de forma consistente.

### Preservação das particularidades da tela

A padronização do cabeçalho não deve remover ou modificar:

- título específico;
- botão de retorno;
- ações da AppBar;
- leitor de QR Code ou código de barras;
- tabs;
- filtros;
- busca;
- conteúdo inferior da AppBar;
- comportamento de seleção;
- scroll;
- navegação;
- estado da tela.

O componente compartilhado deve adaptar-se à tela, e não obrigar a tela a perder funcionalidades para se encaixar no componente.

### Regionalização em telas legadas

Ao migrar cabeçalhos, AppBars ou telas mobile legadas para o padrão oficial, audite também as exibições visíveis ao usuário que costumam ficar acopladas ao legado:

- textos fixos da UI;
- tooltips, labels, títulos, subtítulos, estados vazios, erros e mensagens de ação;
- valores monetários;
- quantidades, totais e números decimais;
- datas e horários.

Para textos do app, prefira `context.t('chave', fallback: 'Texto em pt-BR')` ou mecanismo de i18n existente, mantendo fallback durante a migração quando a chave ainda não existir no backend. Não traduza textos cadastrados pelo usuário ou conteúdos retornados pelo backend como conteúdo livre.

Para moeda, datas, horas e números, consuma sempre `LocaleSettingsProvider` via `context.watch`, `context.read` ou `context.select`. Não instancie `LocaleSettingsProvider()` manualmente e não mantenha `NumberFormat.currency(locale: 'pt_BR', symbol: 'R$')`, `DateFormat('dd/MM', 'pt_BR')`, separadores `.`/`,` ou símbolos/códigos de moeda hardcoded dentro da tela quando o valor for exibido ao usuário.

Para valores monetários, use `context.read<LocaleSettingsProvider>().formatCurrency(valor)` ou helper local que delegue para o provider global. Para data e hora, combine `formatDate` e `formatTime` do provider ou helper centralizado equivalente. Para quantidades e números, preserve o valor numérico bruto e aplique formatação apenas na renderização.

Não altere payloads, DTOs, providers, endpoints ou códigos técnicos enviados ao backend para acomodar tradução. Labels traduzidos são somente de apresentação.

## Componentes e estados

Cards mobile devem usar superfícies, bordas, sombras e hierarquia coerentes com a paleta mobile. Gradientes e sombras precisam comunicar estado, prioridade ou agrupamento; não devem ser ornamentais.

Estados vazios devem explicar o que acontece, indicar próxima ação, evitar CTA duplicado com FAB e funcionar com animações desabilitadas. Verifique se o estado vazio desaparece ou muda quando o primeiro item é incluído.

Antes de adicionar ou manter FAB, verifique duplicidade com CTA de conteúdo, utilidade por estado da tela, ergonomia e uso de `SixMobilePalette.accent`.

### Loading estrutural com ícones preservados

Em telas mobile que carregam dados do backend, quando a estrutura da tela, os tipos de cards, ícones, ações ou categorias já forem conhecidos antes da response, mantenha esses elementos visíveis durante o loading. Use skeleton, pulse ou placeholders apenas nos textos, números, badges, subtítulos e detalhes que dependem da resposta.

Use a intenção da tela `lib/presentation/screens/catalog_health_mobile_screen.dart` como referência: o estado de carregamento deve preservar a leitura do painel, manter o usuário orientado sobre quais áreas existem e evitar uma tela genérica sem identidade enquanto o backend responde.

Preferir:

- cards no mesmo formato final, com ícone estático e superfície do design system;
- skeleton nos valores, metadados e descrições dinâmicas;
- `Semantics(container: true, liveRegion: true, label: 'Carregando...')` para anunciar o carregamento;
- `AnimatedSwitcher` ou transição curta ao trocar de loading para erro, vazio ou sucesso;
- chaves estáveis por estado para evitar animações indevidas;
- respeito a `MediaQuery.disableAnimations` e `MediaQuery.accessibleNavigation`.

Evitar:

- substituir toda a tela por spinner central quando houver layout conhecido;
- esconder ícones e ações estáticas até a response chegar;
- criar skeletons completamente genéricos que não representem a tela final;
- permitir toque em ações que dependem de dados ainda não carregados, salvo quando forem ações independentes e seguras;
- bloquear leitura, acessibilidade ou estabilidade visual por causa do loading.

## Motion, Lottie e loading

O movimento deve ser funcional: explicar mudança de estado, orientar atenção, dar feedback e criar continuidade. Priorize recursos existentes: `SixStaggeredEntry`, `SixAnimatedNumberText`, `SixPulsingBadge`, `AnimatedSwitcher`, `AnimatedContainer`, `AnimatedScale`, `FadeTransition`, `SlideTransition`, `TweenAnimationBuilder`, `flutter_animate`, `SixMobileAnimatedGradientBackground`, `SixLottieActionOverlay`, `SixFullScreenLottieLoading` e `SixBackendLoading`.

Não adicione dependência de animação sem justificativa e autorização. Respeite `MediaQuery.disableAnimations` em animações contínuas ou ambiente animado.

Para Lottie, reutilize `SixAnimationAssets` quando possível, registre novos JSONs centralmente, use `assets/animations/`, preserve `Semantics`, forneça fallback visual e não adicione Rive sem decisão explícita.

## Bottom sheets, textos e acessibilidade

Siga `docs/ui/mobile-first-patterns.md`: seletores mobile devem preferir bottom sheets, busca quando necessário, i18n existente com fallback em pt-BR durante migração, `SafeArea`, fechamento previsível e componentes reutilizáveis.

Bottom sheets de fluxo de negócio, configuração, seleção ou formulário não devem
ficar excessivamente baixos, deixando grande área escurecida/vazia da tela base
acima do modal. Use altura mínima proporcional ao viewport, `DraggableScrollableSheet`
ou constraints responsivas quando fizer sentido, com conteúdo alinhado ao topo e
rolável. Ao mesmo tempo, evite sheets altos com vazio interno grande abaixo do
conteúdo; a superfície deve parecer intencional e ocupada.

Avalie contraste, tamanho de toque, `Semantics`, labels de ícones, foco quando aplicável, ordem de leitura, conteúdo dinâmico, `liveRegion`, redução de movimento, escala de texto e overflow. Não dependa somente de cor para erro, sucesso ou seleção.

### Padrão obrigatório para seletores e dropdowns mobile

Em telas mobile novas, e em telas mobile existentes quando a alteração tocar seleção de entidade, data, filtro, status, forma de pagamento, categoria ou opção equivalente, trate o uso direto de `DropdownButtonFormField`, `DropdownMenu`, `showDatePicker`, `DatePickerDialog` ou dialogs genéricos de seleção como padrão legado.

O padrão default deve ser:

- campo visual read-only/clicável na tela base, com ícone semântico, label, valor selecionado com `TextOverflow.ellipsis`, borda/superfície coerente com `SixMobilePalette`, área de toque confortável e sem deslocar o layout;
- `showModalBottomSheet` customizado com `SafeArea`, cantos superiores arredondados, transição suave, título claro, ação de cancelar previsível e conteúdo em pt-BR ou i18n existente;
- busca local quando a lista já estiver carregada e houver lista média/grande de clientes, fornecedores, produtos, serviços, técnicos, categorias, formas de pagamento ou similares;
- itens confortáveis com avatar/ícone quando fizer sentido, título, subtítulo opcional, estado selecionado destacado e sem depender apenas de cor;
- fechamento imediato após seleção simples quando a ação for reversível e clara; botão `Aplicar` quando houver multi-seleção, intervalo de data, filtros combinados ou mudança que não deve alterar o estado antes da confirmação;
- preservação do valor original até confirmação em seletores de data, período, filtros e multi-seleção;
- `Semantics`, labels de botões/ícones, foco previsível, suporte a texto maior e respeito a `MediaQuery.disableAnimations`/`accessibleNavigation` quando houver movimento.

Ao editar tela existente, audite os seletores visíveis no fluxo alterado. Se o seletor legado fizer parte do fluxo tocado ou do mesmo bloco visual, migre para este padrão no mesmo patch. Se a tela tiver vários seletores legados fora do escopo direto, não faça refatoração ampla automática; registre o resíduo no relato final.

Antes de criar um novo componente, procure padrão reutilizável em `lib/presentation/components/mobile/` ou tela mobile equivalente. Quando houver repetição clara, crie componente próprio reutilizável, como `ClienteSelectorMobileBottomSheet`, `ProdutoSelectorMobileBottomSheet`, `DateSelectorMobileBottomSheet`, `EntitySelectorMobileBottomSheet` ou `QuickDateSelectorMobileBottomSheet`.

Esse padrão é mobile. Não aplique esta regra a arquivos `*_web.dart`, `*_web_page.dart` ou `*_web_dialog.dart`; seletores web devem seguir padrão web próprio e pedido explícito.

## Proibições

Nunca, em tarefa visual mobile:

- duplicar client HTTP, request, response, parser, mapper ou service;
- alterar contrato de backend para acomodar layout;
- mover regra de negócio para widget;
- introduzir novo gerenciador de estado sem autorização;
- modificar autenticação, tenant, permissões ou parsing sem relação direta com o pedido;
- alterar tema global ou fluxo web como primeira opção;
- fazer refatoração ampla, formatação em massa, commit ou push sem pedido explícito.
